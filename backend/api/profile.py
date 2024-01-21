from flask import request

from common import init_profile, hydrate_items, json_resp, handle_errs

from .app import app, get_ctx

@app.route('/profile', methods=('get',))
@handle_errs
def get_profile():
    ctx = get_ctx()

    if not ctx.profile:
        init_profile(ctx, ctx.user.id)

    profile = ctx.profile
    profile['items'] = hydrate_items(ctx, profile['items'])

    return json_resp(profile)

@app.route('/profile', methods=('patch',))
@handle_errs
def patch_profile():
    ctx = get_ctx()

    # todo validation
    client_items = request.json['items']
    for client_item in client_items:
        real_item = ctx.validate_item_authz(client_item)
        
        if 'position' in client_item:
            ctx.db.items.update_one(
                { '_id': real_item['_id'] },
                {
                    '$set': { 'position': client_item['position'] },
                    '$unset': { 'attachment': '' }
                }
            )
        elif 'attachment' in client_item:
            ctx.db.items.update_one(
                { '_id': real_item['_id'] },
                {
                    '$set': { 'attachment': client_item['attachment'] },
                    '$unset': { 'position': '' }
                }
            )

    return json_resp({ 'success': True })
