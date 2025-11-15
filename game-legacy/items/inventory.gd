extends Node3D

var _slots = null
var _host_node = null

func _ready():
	_host_node = get_parent()
	_slots = get_children()

func pick_slot_for(item):
	for slot in _slots:
		if slot.can_accept_item(item):
			return slot
	return null

func slot_containing(item):
	for slot in _slots:
		if slot.active_item == item:
			return slot
	return null

func items():
	var items = []
	for slot in _slots:
		if slot.active_item != null:
			items.append(slot.active_item)
	return items

func register_insert_as_effect(item, slot_name):
	var slot = get_node(slot_name)
	if not slot.can_accept_item(item):
		print('err invalid slot')
		return

	slot.active_item = item

func register_remove_as_effect(item):
	var slot = slot_containing(item)
	if slot == null:
		print('err remove not present')
		return

	slot.active_item = null
