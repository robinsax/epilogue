import os
import json
from flask import Flask, Response, request
from pymongo import MongoClient
from bson import ObjectId
from pymongo.database import Database

from common import rewrite_ids

app = Flask(__name__)

class ErrorResponse(BaseException):

    def __init__(self, message, code):
        self.message = message
        self.code = code

class User:
    id: str
    name: str

class Context:
    user: User
    mongo: MongoClient
    db: Database
    _profile: dict = None

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

def get_ctx() -> Context:
    return request.ctx

def to_json(data, status=200):
    rewrite_ids(data)

    return Response(
        json.dumps(data, default=str),
        status,
        { 'Content-Type': 'application/json' }
    )

def handle_errs(endpoint_fn):
    def wrapper(*args, **kwargs):
        try:
            return endpoint_fn(*args, **kwargs)
        except ErrorResponse as err:
            print('client error:', err.message)
            return to_json({ 'error': err.message }, err.code)
    wrapper.__name__ = endpoint_fn.__name__ + '_wrapped'
    return wrapper

@app.before_request
def authz():
    user = User()
    user.id = user.name = request.args.get('user', 'defaultuser')

    ctx = Context()
    ctx.user = user
    ctx.mongo = MongoClient(os.environ['DATABASE_URI'])
    ctx.db = ctx.mongo.main

    request.ctx = ctx
