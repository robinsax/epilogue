class_name Item extends RigidBody3D

static var SIZE_SMALL = 1
static var SIZE_MEDIUM = 2
static var SIZE_LARGE = 3

@export var size: int = 1
@export var label: String = "Item"

@export var attachment: String = ""
var _last_attachment: String = ""

var inventory: Inventory = null

var current_slot: InventorySlot = null
var current_slot_parenting: RemoteTransform3D = null

func _ready():
	inventory = $Inventory

func _process(delta):
	_update_attachment()

func _update_attachment():
	if attachment == _last_attachment:
		return
	_last_attachment = attachment

	var is_detach = attachment.length() == 0
	if is_detach:
		linear_velocity = Vector3.ZERO

	if current_slot != null:
		current_slot.remove_child(current_slot_parenting)
		current_slot_parenting = null

		# Same-tick updates may have switched the item.
		if current_slot.item == self:
			current_slot.item = null

		current_slot = null

	if is_detach:
		return

	var parts = attachment.split("/")
	var parent_type = parts[0]
	var parent_id = parts[1]
	var slot_key = parts[2]

	var parent_inventory: Inventory = null
	if parent_type == "c":
		parent_inventory = World.current.get_character(parent_id).inventory
	elif parent_type == "i":
		parent_inventory = World.current.items.find_child(parent_id).inventory

	current_slot = parent_inventory.get_slot(slot_key)
	current_slot.item = self
	current_slot_parenting = RemoteTransform3D.new()
	current_slot_parenting.remote_path = get_path()
	current_slot_parenting.update_scale = false
	current_slot.add_child(current_slot_parenting)
	current_slot_parenting.position = -1.0 * get_hold_position()

func get_hold_position():
	return Vector3.ZERO

@rpc("any_peer", "call_local")
func update_attachment(new_attachment: String):
	if not is_multiplayer_authority():
		return

	attachment = new_attachment
