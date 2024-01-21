from flask import request
from datetime import datetime

from common import Context, handle_errs, json_resp, hydrate_items, rewrite_ids

from .app import app, get_ctx
from .matchmaking import get_matchmaker
from .infra import InfraError, get_infra_driver

@app.route('/match/<match_id>', methods=('get',))
@handle_errs
def provide_match_data(match_id=None):
    ctx = get_ctx()

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id)
    })
    ctx.validate_exists(match, 'invalid match')

    profiles = ctx.db.profiles.find({
        '_id': { '$in': match['profile_ids'] }
    })

    profile_lookup = dict()
    for profile in profiles:
        profile_lookup[str(profile['_id'])] = profile

    # todo stupid
    items = list(ctx.db.items.find({
        'world_type': 'match',
        'world_id': match['_id']
    }))
    items = hydrate_items(ctx, list(item['_id'] for item in items))

    return json_resp({ 'items': items, 'profiles': profile_lookup })

@app.route('/match/<match_id>', methods=('post',))
@handle_errs
def update_match_state(match_id=None):
    ctx = get_ctx()

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id)
    })
    ctx.validate_exists(match, 'invalid match')

    update = None
    if request.json['state'] == 'active':
        update = {
            'state': 'active',
            'started_at': datetime.now()
        }
    elif request.json['state'] == 'ended':
        update = {
            'state': 'ended',
            'ended_at': datetime.now()
        }
    if not update:
        return json_resp({ 'error': 'invalid state' }, 400)

    ctx.db.matches.update_one(
        { '_id': match['_id'] },
        { '$set': update }
    )

    return json_resp({ 'success': True })

@app.route('/match/<match_id>/player-results/<profile_id>', methods=('post',))
@handle_errs
def update_player_leave(match_id=None, profile_id=None):
    ctx = get_ctx()
    
    # todo validation

    profile = ctx.db.profile.find_one({
        '_id': ctx.validate_oid(profile_id)
    })
    ctx.validate_exists(profile, 'invalid profile')

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id)
    })
    ctx.validate_exists(match, 'invalid match')

    items = request.json['items']
    for client_item in items:
        real_item = ctx.db.items.find_one({
            '_id': ctx.validate_oid(client_item['id'])
        })
        ctx.validate_exists(real_item, 'invalid item')

        if real_item['world_type'] != 'match' and real_item['world_id'] != match['_id']:
            return json_resp({ 'error': 'item state invalid' }, 400)

        ctx.db.items.update_one(
            { '_id': real_item['_id'] },
            {
                '$set': {
                    'world_type': 'home',
                    'world_id': profile['_id'],
                    'attachement': client_item['attachment']
                },
                '$unset': { 'position': '' }
            }
        )

    return json_resp({ 'success': True })

def manage_matches(ctx: Context):
    driver = get_infra_driver()

    pending_matches = list(ctx.db.matches.find({
        'state': 'pending'
    }))
    for match in pending_matches:
        print('allocate %s'%match['_id'])

        address = None
        try:
            address = driver.allocate(match)
        except InfraError as err:
            print(err)
            # todo: ???
            continue

        print('at %s'%address)

        ctx.db.matches.update_one(
            { '_id': match['_id'] },
            { '$set': {
                'state': 'allocated',
                'address': address
            } }
        )
    
    ended_matches = list(ctx.db.matches.find({
        'state': 'ended'
    }))
    for match in ended_matches:
        print('deallocate %s'%match['_id'])

        try:
            driver.deallocate(match)
        except InfraError as err:
            print(err)
            # todo: ???
            continue
        
        ctx.db.matches.update_one(
            { '_id': match['_id'] },
            { '$set': { 'state': 'complete' } }
        )
        ctx.db.queue.update_many(
            { 'match_id': match['_id'] },
            { '$set': { 'state': 'complete' } }
        )

def do_matchmaking(ctx: Context):
    queue = list(ctx.db.queue.find({ 'state': 'pending' }))

    matched = get_matchmaker().match(queue)
    # todo rm from queue if not refetched for interval

    for group in matched:
        entry_ids = list(entry['_id'] for entry in group)
        profile_ids = list(entry['profile_id'] for entry in group)

        print('matched', profile_ids)

        result = ctx.db.matches.insert_one({
            'profile_ids': profile_ids,
            'state': 'pending',
            'created_at': datetime.now(),
            'booted_at': None,
            'started_at': None,
            'ended_at': None,
            'address': None
        })
        ctx.db.queue.update_many(
            { '_id': { '$in': entry_ids } },
            { '$set': {
                'match_id': result.inserted_id,
                'state': 'active'
            } }
        )
        ctx.db.items.update_many(
            { 'world_id': { '$in': entry_ids } },
            { '$set': {
                'world_type': 'match',
                'world_id': result.inserted_id
            } }
        )
