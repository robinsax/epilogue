from flask import request
from datetime import datetime

from common import json_resp, handle_errs

from .app import app, get_ctx

@app.route('/match/<match_id>', methods=('get',))
@handle_errs
def get_match(match_id=None):
    ctx = get_ctx()

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id),
        'profile_ids': ctx.profile['_id']
    })
    ctx.validate_exists(match, 'invalid match')

    return json_resp(match)

@app.route('/queue', methods=('post',))
@handle_errs
def enter_queue():
    ctx = get_ctx()

    profile = ctx.profile
    ctx.validate_exists(profile, 'invalid profile')

    if profile['active_match']:
        return json_resp({ 'error': 'already in a match' }, 400)

    entry = ctx.db.queue.find_one({
        'profile_id': profile['_id'],
        'state': { '$ne': 'complete' }
    })
    if entry:
        return json_resp({ 'error': 'already in queue' }, 400)

    ctx.db.queue.insert_one({
        'profile_id': profile['_id'],
        'state': 'pending',
        'match_id': None,
        'created_at': datetime.now()
    })
    # todo stupid
    entry = ctx.db.queue.find_one({
        'profile_id': profile['_id'],
        'state': 'pending'
    })

    # todo validation
    submitted_items = request.json['items']
    for client_item in submitted_items:
        real_item = ctx.validate_item_authz(client_item)

        ctx.db.items.update_one(
            { '_id': real_item['_id'] },
            {
                '$set': {
                    'world_type': 'queue',
                    'world_id': entry['_id'],
                    'attachment': client_item['attachment']
                },
                '$unset': { 'position': '' }
            }
        )

    return json_resp(entry)

@app.route('/queue', methods=('get',))
@handle_errs
def get_queue():
    ctx = get_ctx()

    profile = ctx.profile
    ctx.validate_exists(profile, 'invalid profile')

    entry = ctx.db.queue.find_one({
        'profile_id': profile['_id'],
        'state': { '$ne': 'complete' }
    })
    ctx.validate_exists(entry, 'not in queue')

    return json_resp(entry)
