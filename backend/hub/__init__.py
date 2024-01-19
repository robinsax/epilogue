import os
import time
from pymongo import MongoClient

from .common import Context
from .matches import do_matchmaking, manage_matches

def run():
    print('boot')

    ctx = Context()
    ctx.mongo = MongoClient(os.environ['DATABASE_URI'])
    ctx.db = ctx.mongo.main

    while True:
        time.sleep(2.0)

        do_matchmaking(ctx)
        manage_matches(ctx)
