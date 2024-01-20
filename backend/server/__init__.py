# todo do all in engine with api calls?
import os
import time
import subprocess
from datetime import datetime
from pymongo import MongoClient
from bson.objectid import ObjectId

def run():
    match_id = ObjectId(os.environ['MATCH_ID'])
    print('init match server for %s'%match_id)

    mongo = MongoClient(os.environ['DATABASE_URI'])
    db = mongo.main

    # todo write match info to server

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
