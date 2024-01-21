import json
from flask import Response

class ErrorResponse(BaseException):

    def __init__(self, message, code):
        self.message = message
        self.code = code

def rewrite_ids(item):
    if isinstance(item, dict):
        if '_id' in item:
            item['id'] = item.pop('_id')
        
        for value in item.values():
            rewrite_ids(value)
    elif isinstance(item, list):
        for child in item:
            rewrite_ids(child)

def json_resp(data, status=200):
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
            return json_resp({ 'error': err.message }, err.code)
    wrapper.__name__ = endpoint_fn.__name__ + '_wrapped'
    return wrapper
