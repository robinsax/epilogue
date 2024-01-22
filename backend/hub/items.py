from flask import request
from random import random

from common import handle_errs, json_resp, load_yaml

from .app import app, get_ctx

item_pools = load_yaml('item_pools.yml') # todo store in db for dynamics

def roll_pool(pool):
    roll = random()
    
    for entry in pool:
        if roll < entry['chance']:
            return entry['ref']
        
        roll -= entry['chance']

    return None

@app.route('/match/<match_id>/item-pool', methods=('post',))
@handle_errs
def create_items(match_id=None):
    ctx = get_ctx()

    # todo validation

    match = ctx.db.matches.find_one({
        '_id': ctx.validate_oid(match_id)
    })
    ctx.validate_exists(match, 'invalid match')

    pool_result = list()
    for item_req in request.json:
        roll_result = roll_pool(item_pools[item_req['pool']])

        if not roll_result:
            continue

        type_info = ctx.db.item_types.find_one({
            'ref': roll_result
        })
        ctx.validate_exists(type_info, 'invalid type ref')

        result = ctx.db.items.insert_one({
            'type_id': type_info['_id'],
            'world_type': 'match',
            'world_id': match['_id'],
            'position': item_req['position']
        })

        # todo stupid
        created = ctx.db.items.find_one({
            '_id': result.inserted_id
        })
        created['type'] = type_info
        del created['type_id']

        pool_result.append(created)

    return json_resp({ 'items': pool_result })
