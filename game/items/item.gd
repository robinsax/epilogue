class_name Item extends RigidBody3D

static var AUDIO_BASE = 0
static var AUDIO_CUSTOM = 1

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
@export var attach_clip_count: int = 4

@export var repl_world_position: Vector3
@export var repl_world_rotation: Vector3
@export var attachment: String = ""
var _last_attachment: String
var _play_attachment: bool

var inventory: Inventory
var base_audio: ClippedAudioPlayer
var custom_audio: ClippedAudioPlayer

var current_slot: InventorySlot
var is_animated: bool
var update_culled: bool
var hard_culled_position: Vector3

func _ready():
	inventory = $Inventory
	base_audio = $BaseAudio
	custom_audio = $CustomAudio

func _process(delta):
	if _play_attachment:
		base_audio.play_random_clip(0, attach_clip_count, true)
		_play_attachment = false

	_update_attachment()

func _physics_process(delta: float):
	if is_multiplayer_authority():
		repl_world_position = global_position
		repl_world_rotation = global_rotation
	elif attachment.length() == 0:
		global_position = repl_world_position
		global_rotation = repl_world_rotation

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

	_play_attachment = true

	var is_detach = attachment.length() == 0
	if is_detach:
		_set_body_enabled(true)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

	if current_slot != null and current_slot.item == self:
		# Same-tick updates may have switched the item.
		if current_slot.item == self:
			current_slot.item = null
		current_slot = null

	if is_detach:
		return

	_set_body_enabled(false)
	collision_layer = CollisionLayers.WORLD_UI

	current_slot = _resolve_attachment()
	current_slot.item = self
	current_slot.pending_item = null

func _set_body_enabled(enabled: bool):
	freeze = not enabled
	sleeping = not enabled
	set_physics_process_internal(enabled)
	if enabled:
		collision_layer = CollisionLayers.ITEMS | CollisionLayers.FOLIAGE_IMPACTORS
		collision_mask = CollisionLayers.PHYSICAL
	else:
		collision_layer = 0
		collision_mask = 0

func set_culled(cull: bool):
	update_culled = cull

	_set_body_enabled(not cull and attachment.length() == 0)

func update_as_attached(character: RobotBipedCharacter, delta: float):
	return

func wants_animate_biped(character: RobotBipedCharacter) -> bool:
	return false

func animate_biped_as_active(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	pass

func reload_as_active(character: Character):
	pass

func get_hold_position() -> Vector3:
	return Vector3.ZERO

func get_detail_string() -> String:
	return ""

@rpc("any_peer", "call_local")
func update_attachment(new_attachment: String):
	if not is_multiplayer_authority():
		return

	attachment = new_attachment
	if attachment.length() > 0:
		_resolve_attachment().pending_item = self
