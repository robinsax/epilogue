class_name Inventory extends Node

var _owner: Node3D = null
var _slots: Array[InventorySlot] = []

func _ready():
	_owner = get_parent()

	_discover_slots(owner)

func _discover_slots(current: Node):
	if current is InventorySlot:
		_slots.push_back(current)

	for child in current.get_children():
		_discover_slots(child)

func _process(delta):
	pass
