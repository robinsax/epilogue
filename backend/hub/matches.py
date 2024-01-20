from datetime import datetime

from .common import Context
from .matchmaking import get_matchmaker
from .infra import InfraError, get_infra_driver

def manage_matches(ctx: Context):
    driver = get_infra_driver()

    matches = list(ctx.db.matches.find({
        'state': { '$ne': 'complete' }
    }))

    print('%d matches'%len(matches))

    for match in matches:
        print(match)
        if match['state'] == 'pending':
            print('allocate %s'%match['_id'])

            address = None
            try:
                address = driver.allocate(match)
            except InfraError as err:
                print(err)
                # todo: ???
                continue

            ctx.db.matches.update_one(
                { '_id': match['_id'] },
                { '$set': {
                    'state': 'provisioned',
                    'address': address
                } }
            )
        elif match['state'] == 'ended':
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

    print('queue size %d'%len(queue))

    matched = get_matchmaker().match(queue)
    # todo rm from queue if not refetched for interval

    for group in matched:
        entry_ids = list(entry['_id'] for entry in group)
        user_ids = list(entry['user_id'] for entry in group)

        print('matched', user_ids)

        result = ctx.db.matches.insert_one({
            'user_ids': user_ids,
            'state': 'pending',
            'created_at': datetime.now(),
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

def matchmake_simple(queue: list):
    matched = list()

    while len(queue) >= 2:
        matched.append(list((queue.pop(), queue.pop())))

    return matched
