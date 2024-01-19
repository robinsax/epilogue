from datetime import datetime
from bson.objectid import ObjectId

from .app import app, get_ctx, to_json

@app.route('/match/<match_id>', methods=('get',))
def get_match(match_id=None):
    ctx = get_ctx()

    try:
        match_id = ObjectId(match_id)
    except:
        return to_json({ 'error': 'invalid id' }, 400)

    match = ctx.db.matches.find_one({
        'user_ids': ctx.user.id,
        '_id': match_id
    })
    if not match:
        return to_json({ 'error': 'not found' }, 404)

    return to_json(match)

@app.route('/queue', methods=('get',)) # todo: post
def queue_match():
    ctx = get_ctx()

    entry = ctx.db.queue.find_one({
        'user_id': ctx.user.id,
        'state': { '$ne': 'complete' }
    })
    if entry:
        return to_json(entry)

    ctx.db.queue.insert_one({
        'user_id': ctx.user.id,
        'state': 'pending',
        'match_id': None,
        'created_at': datetime.now()
    })

    entry = ctx.db.queue.find_one({
        'user_id': ctx.user.id,
        'state': 'pending'
    })
    return to_json(entry)
