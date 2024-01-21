extends Node3D

var _slots = {}
var _host_node = null

func _ready():
	_host_node = get_parent()
	
	for slot_node in get_children():
		_slots[slot_node.name] = null

func _process(delta):
	for slot_node in get_children():
		var slot_name = slot_node.name
		if _slots[slot_name] == null:
			continue
		_slots[slot_name].position = slot_node.global_position

func _get_free_slot_name_for_item(item):
	for slot_name in _slots.keys():
		if _slots[slot_name] == null:
			return slot_name
	return null

func _get_slot_name_containing_item(item):
	for slot_name in _slots.keys():
		if _slots[slot_name] == item:
			return slot_name
	return null

func items():
	var items = []
	for slot_name in _slots.keys():
		if _slots[slot_name] != null:
			items.append(_slots[slot_name])
	return items

func insert_item_from_rpc(item, slot_name=null):
	if slot_name == null:
		slot_name = _get_free_slot_name_for_item(item)
	if slot_name == null:
		print('err no slot avail')
		return

	if item.active_inventory != null:
		item.active_inventory.remove_item_from_rpc(item)
	_slots[slot_name] = item
	item.set_in_inventory_from_inventory(true)
	item.active_inventory = self

func remove_item_from_rpc(item):
	for slot_name in _slots.keys():
		var slot_item = _slots[slot_name]
		if slot_item != item:
			continue

		_slots[slot_name] = null
		item.set_in_inventory_from_inventory(false)
		item.active_inventory = null
		return

func remove_item_from_destroy(item):
	for slot_name in _slots.keys():
		var slot_item = _slots[slot_name]
		if slot_item != item:
			continue

		_slots[slot_name] = null
		return

func attachment_data_for_item(item):
	var slot_name = _get_slot_name_containing_item(item)
	return [_host_node.attachment_data(), slot_name]
