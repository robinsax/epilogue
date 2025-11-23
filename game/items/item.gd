class_name Item extends RigidBody3D

static var SIZE_SMALL = 1
static var SIZE_MEDIUM = 2
static var SIZE_LARGE = 3

static var RARITY_COMMON = 1
static var RARITY_UNCOMMON = 2
static var RARITY_RARE = 3

@export var size: int = 1
@export var label: String = "Item"
@export var in_slot_rotation: Vector3 = Vector3.ZERO
@export var tags: Array[String] = []
@export var rarity: int = 1
@export var hand_value: int = 1

@export var attachment: String = ""
var _last_attachment: String = ""

var inventory: Inventory = null

var current_slot: InventorySlot = null
var is_animated: bool = false

func _ready():
	inventory = $Inventory

func _process(delta):
	_update_attachment()
	_update_position()

func _update_position():
	var animated = is_animated
	is_animated = false
	if animated:
		return

	if current_slot:
		global_position = current_slot.global_position
		if current_slot.ignore_item_rotation:
			global_rotation = current_slot.global_rotation
		else:
			global_basis = (
				Basis.from_euler(current_slot.global_rotation) *
				Basis.from_euler(in_slot_rotation)
			)

func _resolve_attachment():
	var parts = attachment.split("/")
	var parent_type = parts[0]
	var parent_id = parts[1]
	var slot_key = parts[2]

	var parent_inventory: Inventory = null
	if parent_type == "c":
		parent_inventory = World.current.get_character(parent_id).inventory
	elif parent_type == "i":
		parent_inventory = World.current.get_item(parent_id).inventory

	return parent_inventory.get_slot(slot_key)

func _update_attachment():
	if attachment == _last_attachment:
		return
	_last_attachment = attachment

	var is_detach = attachment.length() == 0
	if is_detach:
		set_physics_process(true)
		set_physics_process_internal(true)
		freeze = false
		set_collision_mask_value(CollisionLayerValues.PHYSICAL, true)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

	if current_slot != null and current_slot.item == self:
		# Same-tick updates may have switched the item.
		if current_slot.item == self:
			current_slot.item = null
		current_slot = null

	if is_detach:
		return

	set_physics_process(false)
	set_physics_process_internal(false)
	set_collision_mask_value(CollisionLayerValues.PHYSICAL, false)
	freeze = true

	current_slot = _resolve_attachment()
	current_slot.item = self
	current_slot.pending_item = null

func animate_biped_as_active(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	pass

func reload_as_active(character: Character):
	pass

func get_hold_position():
	return Vector3.ZERO

@rpc("any_peer", "call_local")
func update_attachment(new_attachment: String):
	if not is_multiplayer_authority():
		return

	attachment = new_attachment
	if attachment.length() > 0:
		_resolve_attachment().pending_item = self
