class_name Inventory extends Node

var _owner: Node3D = null
var _slots: Array[InventorySlot] = []

func _ready():
	_owner = get_parent()

	discover_slots(owner)

func discover_slots(current: Node):
	if current is InventorySlot:
		_slots.push_back(current)
		current.inventory = self

	for child in current.get_children():
		discover_slots(child)

func _process(delta):
	pass

func get_slot(key: String) -> InventorySlot:
	for slot in _slots:
		if slot.key == key:
			return slot

	return null

func get_available_slot_for(item: Item) -> InventorySlot:
	for slot in _slots:
		if slot.is_item_compatible(item) and slot.is_available():
			return slot

	return null

func get_attachment_string(slot: InventorySlot) -> String:
	var owner_type = "i"
	if _owner is Character:
		owner_type = "c"

	return owner_type + "/" + _owner.name + "/" + slot.key

func get_slot_with_item_tag(tag: String) -> InventorySlot:
	for slot in _slots:
		if slot.item != null and tag in slot.item.tags:
			return slot

	return null
