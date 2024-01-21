import os
from bson import ObjectId
from pymongo import MongoClient
from pymongo.database import Database

from .api import ErrorResponse

class User:
    id: str
    name: str

class Context:
    user: User
    mongo: MongoClient
    db: Database
    _profile: dict

    @classmethod
    def create(cls, user=None):
        ctx = cls()
        ctx.user = user
        ctx.mongo = MongoClient(os.environ['DATABASE_URI'])
        ctx.db = ctx.mongo.main
        ctx._profile = None
        return ctx

    @property
    def profile(self):
        if not self._profile:
            self._profile = self.db.profiles.find_one({
                'user_id': self.user.id
            })
        return self._profile

    def validate_oid(self, oid_str):
        try:
            return ObjectId(oid_str)
        except:
            raise ErrorResponse('invalid oid', 400)
        
    def validate_exists(self, obj, err_msg):
        if not obj:
            raise ErrorResponse(err_msg, 400)

    def validate_item_authz(self, item_data):
        real_item = self.db.items.find_one({
            '_id': self.validate_oid(item_data['id']),
            'world_type': 'home',
            'world_id': self.profile['_id']
        })
        if not real_item:
            raise ErrorResponse('item authz', 400)
    
        return real_item
