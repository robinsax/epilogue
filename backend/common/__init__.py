import yaml
from pymongo.database import Database

def load_yaml(which):
    with open('common/' + which) as yaml_f:
        return yaml.safe_load(yaml_f)

def rewrite_ids(item):
    if isinstance(item, dict):
        if '_id' in item:
            item['id'] = item.pop('_id')
        
        for value in item.values():
            rewrite_ids(value)
    elif isinstance(item, list):
        for child in item:
            rewrite_ids(child)

def hydrate_items(db: Database, item_ids):
    # todo aggregate
    hydrated_items = list(db.items.find({
        '_id': { '$in': item_ids }
    }))
    for item in hydrated_items:
        item['type'] = db.item_types.find_one({
            '_id': item['type_id']
        })
        del item['type_id']
    return hydrated_items

def init_db(db: Database):
    db.item_types.insert_many(load_yaml('item_types.yml'))

    print(list(db.item_types.find()))

def init_profile(db: Database, username):
    result = db.profiles.insert_one({
        'user_id': username,
        'items': []
    })
    profile_id = result.inserted_id

    items_archetype = load_yaml('init_home.yml')
    items = list()
    for entry in items_archetype:
        item_type = db.item_types.find_one({ 'ref': entry['ref'] })
        
        item_doc = {
            'type_id': item_type['_id'],
            'world_type': 'home',
            'world_id': profile_id,
            **entry.get('instance_fields', dict())
        }
        if 'position' in entry:
            item_doc['position'] = entry['position']
        elif 'attachment' in entry:
            item_doc['attachment'] = entry['attachment']

        result = db.items.insert_one(item_doc)
        
        items.append(result.inserted_id)

    db.profiles.update_one(
        { '_id': profile_id },
        { '$set': {
            'items': items
        }
    })
