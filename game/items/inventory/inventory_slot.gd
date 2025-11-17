class_name InventorySlot extends Node3D

@export var size: int = Item.SIZE_SMALL
@export var key: String = "slot"
@export var ui_size: float = 1.0

var item: Item = null
var inventory: Inventory = null
var _ui_view: MeshInstance3D = null
var _collider: CollisionObject3D = null

func _ready():
	_ui_view = $UIView
	_collider = $Collider

func _process(delta):
	if PlayerPossession.current != null:
		_ui_view.visible = PlayerPossession.current.in_inventory

	var parent_global_scale = global_transform.basis.get_scale()
	var scaling = Vector3(
		1.0 / parent_global_scale.x,
		1.0 / parent_global_scale.y,
		1.0 / parent_global_scale.z
	) * ui_size

	_ui_view.scale = scaling
	_collider.scale = scaling

func is_item_compatible(check_item: Item) -> bool:
	return check_item.size <= size

func is_available() -> bool:
	return item == null

func get_attachment_string():
	return inventory.get_attachment_string(self)
