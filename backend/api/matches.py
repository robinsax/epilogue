from flask import request
from datetime import datetime
from bson import ObjectId

from .app import app, get_ctx, to_json, handle_errs

@app.route('/match/<match_id>', methods=('get',))
@handle_errs
def get_match(match_id=None):
    ctx = get_ctx()

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id),
        'user_ids': ctx.user.id
    })
    ctx.validate_exists(match, 'invalid match')

    return to_json(match)

@app.route('/queue', methods=('post',))
@handle_errs
def enter_queue():
    ctx = get_ctx()

    entry = ctx.db.queue.find_one({
        'user_id': ctx.user.id,
        'state': { '$ne': 'complete' }
    })
    if entry:
        return to_json({ 'error': 'already in queue' }, 400)

    result = ctx.db.queue.insert_one({
        'user_id': ctx.user.id,
        'state': 'pending',
        'match_id': None,
        'created_at': datetime.now()
    })
    # todo stupid
    entry = ctx.db.queue.find_one({
        'user_id': ctx.user.id,
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

    return to_json(entry)

@app.route('/queue', methods=('get',))
@handle_errs
def get_queue():
    ctx = get_ctx()

    entry = ctx.db.queue.find_one({
        'user_id': ctx.user.id,
        'state': { '$ne': 'complete' }
    })
    ctx.validate_exists(entry, 'not in queue')

    return to_json(entry)
