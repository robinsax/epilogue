import os
import time
from datetime import datetime
from pymongo import MongoClient
from bson.objectid import ObjectId

def run():
    match_id = ObjectId(os.environ['MATCH_ID'])
    print('init match server for %s'%match_id)

    mongo = MongoClient(os.environ['DATABASE_URI'])
    db = mongo.main

    db.matches.update_one(
        { '_id': match_id },
        { '$set': {
            'state': 'active'
        } }
    )

    print('booting server...')

    time.sleep(60.0)

    print('done')

    db.matches.update_one(
        { '_id': match_id },
        { '$set': {
            'state': 'ended',
            'ended_at': datetime.now()
        } }
    )

    time.sleep(100.0)
