# todo do all in engine with api calls?
import os
import time
import json
import subprocess
from datetime import datetime
from pymongo import MongoClient
from bson import ObjectId

from common import rewrite_ids, hydrate_items

def run():
    match_id = ObjectId(os.environ['MATCH_ID'])
    print('init match server for %s'%match_id)

    mongo = MongoClient(os.environ['DATABASE_URI'])
    db = mongo.main

    match_data_path = os.path.join(os.path.curdir, 'match_data.json')
    print('collecting match data to ' + match_data_path)

    # todo trash
    items = list(db.items.find({
        'world_type': 'match',
        'world_id': match_id
    }))
    items = hydrate_items(db, list(item['_id'] for item in items))
    rewrite_ids(items)

    match_data = { 'items': items }

    with open(match_data_path, 'w') as match_data_f:
        json.dump(match_data, match_data_f, default=str)

    os.environ['MATCH_DATA_PATH'] = match_data_path

    db.matches.update_one(
        { '_id': match_id },
        { '$set': {
            'state': 'active',
            'started_at': datetime.now()
        } }
    )

    print('booting server...')
    result = subprocess.run(
        f'''
        ./service/server/server
            --headless
            --verbose
        '''.strip().split()
    )
    print('exited with %d'%result.returncode)

    db.matches.update_one(
        { '_id': match_id },
        { '$set': {
            'state': 'ended',
            'ended_at': datetime.now()
        } }
    )

    time.sleep(60.0) # await infra kill
