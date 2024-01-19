from flask import request

from common import create_default_profile

from .app import app, get_ctx, to_json

@app.route('/profile', methods=('get',))
def get_profile():
    ctx = get_ctx()

    profile = ctx.db.profiles.find_one({
        'username': ctx.user.id
    })
    if not profile:
        request.db.profiles.insert_one(
            create_default_profile(ctx.user.id)
        )
        profile = ctx.db.profiles.find_one({
            'username': ctx.user.id
        })
    
    return to_json(profile)
