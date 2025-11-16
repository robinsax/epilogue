class_name Item extends RigidBody3D

static var SIZE_SMALL = 1
static var SIZE_MEDIUM = 2
static var SIZE_LARGE = 3

@export var size: int = 1
@export var label: String = "Item"

@export var attachment: String = ""
var _last_attachment: String = ""

var _slot: InventorySlot = null
var _transform_parenting: RemoteTransform3D = null

func _process(delta):
	_update_attachment()

func _update_attachment():
	if attachment == _last_attachment:
		return
	_last_attachment = attachment

	var is_detach = attachment.length() == 0
	if is_detach:
		set_collision_layer_value(1, true)
		linear_velocity = Vector3.ZERO

	if _slot:
		_slot.remove_child(_transform_parenting)
		_slot.item = null
		_transform_parenting = null
		_slot = null

	if is_detach:
		return

	var parts = attachment.split("/")
	var parent_type = parts[0]
	var parent_id = parts[1]
	var slot_key = parts[2]

	var inventory: Inventory = null
	if parent_type == "c":
		inventory = World.current.get_character(parent_id).inventory
	elif parent_type == "i":
		inventory = World.current.items.find_child(parent_id).inventory

	_slot = inventory.get_slot(slot_key)
	_slot.item = self
	set_collision_layer_value(1, false)
	_transform_parenting = RemoteTransform3D.new()
	_transform_parenting.remote_path = get_path()
	_transform_parenting.update_scale = false
	_slot.add_child(_transform_parenting)

@rpc("any_peer", "call_local")
func drop():
	if not is_multiplayer_authority():
		return

	attachment = ""

@rpc("any_peer", "call_local")
func update_attachment(new_attachment: String):
	if not is_multiplayer_authority():
		return

	attachment = new_attachment
