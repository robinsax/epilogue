from flask import Flask, request

from common import Context, User

app = Flask(__name__)

def get_ctx() -> Context:
    return request.ctx

@app.before_request
def authz():
    user = User()
    user.id = user.name = request.args.get('user', 'defaultuser')

    request.ctx = Context.create(user)
