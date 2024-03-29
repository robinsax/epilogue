import yaml

from .context import Context

def load_yaml(which):
    with open('common/' + which) as yaml_f:
        return yaml.safe_load(yaml_f)

def init_db(ctx: Context):
    ctx.db.item_types.insert_many(load_yaml('item_types.yml'))

    print(list(ctx.db.item_types.find()))

def init_profile(ctx: Context, username):
    result = ctx.db.profiles.insert_one({
        'user_id': username,
        'items': [],
        'active_match': None
    })
    profile_id = result.inserted_id

    items_archetype = load_yaml('init_home.yml')
    items = list()
    for entry in items_archetype:
        item_type = ctx.db.item_types.find_one({ 'ref': entry['ref'] })
        
        item_doc = {
            'type_id': item_type['_id'],
            'world_type': 'home',
            'world_id': profile_id
        }
        if 'position' in entry:
            item_doc['position'] = entry['position']
        elif 'attachment' in entry:
            item_doc['attachment'] = entry['attachment']

        result = ctx.db.items.insert_one(item_doc)
        
        items.append(result.inserted_id)

    ctx.db.profiles.update_one(
        { '_id': profile_id },
        { '$set': {
            'items': items
        }
    })
