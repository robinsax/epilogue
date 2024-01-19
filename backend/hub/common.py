import os
from pymongo import MongoClient
from pymongo.database import Database

class Context:
    mongo: MongoClient
    db: Database

def pick_implementation(key: str, impls: dict):
    value = os.environ[key]
    if value not in impls:
        raise NotImplementedError('%s=%s'%(key, value))
    
    return impls[value]
