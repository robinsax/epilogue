import os
import json
from flask import Flask, Response, request
from pymongo import MongoClient
from pymongo.database import Database

app = Flask(__name__)

class User:
    id: str
    name: str

class Context:
    user: User
    mongo: MongoClient
    db: Database

def get_ctx() -> Context:
    return request.ctx

def to_json(data, status=200):
    if '_id' in data:
        data['id'] = data.pop('_id')

    return Response(
        json.dumps(data, default=str),
        status,
        { 'Content-Type': 'application/json' }
    )

@app.before_request
def authz():
    user = User()
    user.id = user.name = request.args.get('user', 'defaultuser')

    ctx = Context()
    ctx.user = user
    ctx.mongo = MongoClient(os.environ['DATABASE_URI'])
    ctx.db = ctx.mongo.main

    request.ctx = ctx
