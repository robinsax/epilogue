from flask import Flask, request

from common import Context

app = Flask(__name__)

def get_ctx() -> Context:
    return request.ctx

@app.before_request
def authz():
    # todo authenticate match server only

    request.ctx = Context.create()
