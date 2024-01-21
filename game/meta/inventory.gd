extends Node3D

@export var slots = {}

func _ready():
	for slot_node in get_children():
		slots[slot_node.name] = null

func _process(delta):
	for slot_node in get_children():
		var slot_name = slot_node.name
		if slots[slot_name] == null:
			return
		slots[slot_name].position = slot_node.global_position

func _get_slot_name_for_item(item):
	for slot_name in slots.keys():
		if slots[slot_name] == null:
			return slot_name
	return null

func insert_item_from_rpc(item):
	var slot_name = _get_slot_name_for_item(item)
	if slot_name == null:
		print('err no slot avail')
		return

	if item.active_inventory != null:
		item.active_inventory.remove_item_from_rpc(item)
	slots[slot_name] = item
	item.set_in_inventory_from_inventory(true)
	item.active_inventory = self
	print(to_data())

func remove_item_from_rpc(item):
	for slot_name in slots.keys():
		var slot_item = slots[slot_name]
		if slot_item != item:
			continue

		slots[slot_name] = null
		slot_item.set_in_inventory_from_inventory(false)
		slot_item.active_inventory = null
		print(to_data())
		return

func to_data():
	var slot_dicts = []

	for slot_name in slots.keys():
		var item_info = null
		if slots[slot_name] != null:
			item_info = slots[slot_name].item_name

		slot_dicts.append({
			"slot": slot_name,
			"item": item_info
		})
		
	return slot_dicts
