class_name Inventory extends Node

var _owner: Node3D = null
var _slots: Array[InventorySlot] = []

func _ready():
	_owner = get_parent()

	_discover_slots(owner)

func _discover_slots(current: Node):
	if current is InventorySlot:
		_slots.push_back(current)
		current.inventory = self

	for child in current.get_children():
		_discover_slots(child)

func _process(delta):
	pass

func _all_slots() -> Array[InventorySlot]:
	var all = _slots.duplicate()
	for slot in _slots:
		if slot.item != null:
			all.append_array(slot.item.inventory._all_slots())

	return all

func get_slot(key: String) -> InventorySlot:
	for slot in _all_slots():
		if slot.key == key:
			return slot

	return null

func get_available_slot_for(item: Item) -> InventorySlot:
	for slot in _all_slots():
		if slot.required_tag != "" and slot.is_item_compatible(item) and slot.is_available():
			return slot

	for slot in _all_slots():
		if slot.size == item.size and slot.is_item_compatible(item) and slot.is_available():
			return slot

	for slot in _all_slots():
		if slot.is_item_compatible(item) and slot.is_available():
			return slot

	return null

func get_attachment_string(slot: InventorySlot) -> String:
	var owner_type = "i"
	if _owner is Character:
		owner_type = "c"

	return owner_type + "/" + _owner.name + "/" + slot.key

func get_slot_with_item_tag(tag: String, exclude: Array[InventorySlot] = []) -> InventorySlot:
	for slot in _all_slots():
		if exclude and slot in exclude:
			continue

		if slot.item != null and tag in slot.item.tags:
			return slot

	return null
