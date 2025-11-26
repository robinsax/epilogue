class_name InventorySlot extends Node3D

@export var size: int = Item.SIZE_SMALL
@export var label: String = "Slot"
@export var key: String = "slot"
@export var ui_size: float = 1.0
@export var ui_offset: Vector3 = Vector3.ZERO
@export var required_tag: String = ""
@export var banned_tags: Array[String] = []
@export var ignore_item_rotation: bool = false
@export var access_requires_inventory_mode: bool = false

var pending_item: Item

var item: Item
var inventory: Inventory
var _ui_view: MeshInstance3D
var _collider: CollisionObject3D

func _ready():
	_ui_view = $UIView
	_collider = $Collider

func _process(delta):
	if inventory.update_culled:
		return

	if PlayerPossession.current != null:
		_ui_view.visible = (
			PlayerPossession.current.in_inventory and
			item == null
		)

	var parent_global_scale = global_transform.basis.get_scale()
	var scaling = Vector3(
		1.0 / parent_global_scale.x,
		1.0 / parent_global_scale.y,
		1.0 / parent_global_scale.z
	) * ui_size * 0.5

	_ui_view.scale = scaling
	_ui_view.position = ui_offset
	_collider.position = ui_offset
	_collider.scale = scaling

func compatibility_rank_for(check_item: Item) -> int:
	if not is_item_compatible(check_item):
		return -1

	if required_tag.length() > 0:
		return 3
	if size == check_item.size:
		return 2
	return 1

func is_item_compatible(check_item: Item) -> bool:
	if required_tag.length() > 0 and not (required_tag in check_item.tags):
		return false

	for tag in banned_tags:
		if tag in check_item.tags:
			return false

	return check_item.size <= size

func is_available() -> bool:
	return item == null and pending_item == null

func get_attachment_string():
	return inventory.get_attachment_string(self)
