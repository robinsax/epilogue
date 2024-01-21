import os

from .model import load_yaml, hydrate_items, init_db, init_profile
from .api import ErrorResponse, rewrite_ids, handle_errs, json_resp
from .context import Context, User

def pick_implementation(key: str, impls: dict):
    value = os.environ[key]
    if value not in impls:
        raise NotImplementedError('%s=%s'%(key, value))
    
    return impls[value]
