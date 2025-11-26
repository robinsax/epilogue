class_name PlayerPossession extends Possession

var MOUSE_SENSITIVITY = 0.006

static var _hotkey_binds = [
	"hotkey_1", "hotkey_2", "hotkey_3", "hotkey_4", "hotkey_5"
]

@export var camera_lean_carry: float = 0.15
@export var look_ray_length: float = 30.0
@export var camera_sprint_fov: float = 72.0
@export var camera_zoom_fov: float = 40.0
@export var inventory_rotate_rate: float = 0.2
@export var inventory_camera_arm_length: float = 1.2

static var current: PlayerPossession = null

var _global_room_tone: AudioStreamPlayer3D

var _camera_arm: SpringArm3D
var _camera: Camera3D
var _character: Character
var _hud: HUD

var _interact_target: Node3D
var _slot_target: InventorySlot
var in_inventory: bool
var _inventory_rotation: float
var _mouse_escaped: bool
var _base_camera_fov: float
var _base_camera_arm_position: Vector3
var _base_camera_arm_length: float
var _look_rotation: Vector3
var _hotkey_set_time: float
var _hotkeys: Dictionary

func _ready():
	super._ready()
	_character = get_parent()
	_camera_arm = $CameraArm
	_camera = $CameraArm/Camera
	_hud = $CameraArm/Camera/HUDLayer/HUD
	_hud.possession = self

	_global_room_tone = $GlobalRoomTone
	if World.current.environment_generator:
		_global_room_tone.stream = World.current.environment_generator.global_room_tone
		_global_room_tone.play()

	_base_camera_fov = _camera.fov
	_base_camera_arm_length = _camera_arm.spring_length
	_base_camera_arm_position = _camera_arm.position

	PlayerPossession.current = self

	if is_authority():
		_camera.set_current(true)

func _physics_process(delta: float):
	_slot_target = null
	var look_cast_screen_position = Vector2.ZERO
	look_cast_screen_position = get_viewport().get_mouse_position()

	if in_inventory:
		var slot_cast_result = _screen_raycast(
			look_cast_screen_position, CollisionLayers.WORLD_UI | CollisionLayers.DAMAGE, true
		)
		if "collider" in slot_cast_result:
			if slot_cast_result.collider.get_parent() is InventorySlot:
				_slot_target = slot_cast_result.collider.get_parent()
	else:
		look_cast_screen_position = get_viewport().size / 2.0

	var ignore_rids: Array[RID] = []
	if not in_inventory:
		ignore_rids = character.get_look_cast_ignore_rids()

	var look_cast_result = _screen_raycast(
		look_cast_screen_position,
		CollisionLayers.PHYSICAL | CollisionLayers.CHARACTERS | CollisionLayers.ITEMS |
		CollisionLayers.WORLD_UI | CollisionLayers.INTERACTION,
		true, ignore_rids
	)
	var hit_distance = INF
	var look_target = Vector3.ZERO
	if "position" in look_cast_result:
		look_target = look_cast_result.position
		hit_distance = (look_cast_result.position - _character.global_position).length()
	else:
		look_target = look_cast_result["to"]

	# TODO: AAAA duplicating
	character.look_target = look_target
	character.aim_target = look_target

	character.object_interact_target = null
	_interact_target = null
	if "collider" in look_cast_result and hit_distance <= _character.interact_reach:
		var hit = look_cast_result.collider
		if hit is Item:
			_interact_target = hit
		if hit is ObjectInteractTarget:
			character.object_interact_target = hit

func _process(delta):
	if not is_authority():
		return

	Stats.stats["player/pos"] = global_position
	Stats.stats["player/spd"] = character.get_current_speed()

	_character.checking_status = Input.is_action_pressed("check_status")
	_character.look_zoomed = false

	if in_inventory:
		_character.aiming = false

		if Input.is_action_pressed("lean_left"):
			_inventory_rotation += inventory_rotate_rate
		elif Input.is_action_pressed("lean_right"):
			_inventory_rotation -= inventory_rotate_rate

		_camera_arm.spring_length = inventory_camera_arm_length
		_camera_arm.position = Vector3.ZERO
		_camera_arm.rotation = Vector3(0.0, _inventory_rotation, 0.0)
	else:
		_inventory_rotation = 0

		_character.look_zoomed = Input.is_action_pressed("zoom_look")

		_camera_arm.spring_length = _base_camera_arm_length
		_camera_arm.position = _base_camera_arm_position
		_camera_arm.rotation.y = 0
		_camera_arm.rotate_x(_look_rotation.x)

		_character.aiming = Input.is_action_pressed("aim")
		_character.firing = Input.is_action_pressed("fire")
		if _character is GroundCharacter:
			_character.crouching = Input.is_action_pressed("crouch")
			_character.sprinting = Input.is_action_pressed("sprint")

			_character.lean = Input.get_axis("lean_right", "lean_left")

	var move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_character.move_direction = Vector3(move_direction.x, 0.0, move_direction.y)
	_character.jumping = false

	_character.rotate_y(_look_rotation.y)
	_look_rotation = Vector3.ZERO

	if _character.sprinting and move_direction.length() > 0:
		_camera.fov = camera_sprint_fov
	elif _character.look_zoomed:
		_camera.fov = camera_zoom_fov
	else:
		_camera.fov = _base_camera_fov
	if _character is GroundCharacter:
		_camera.rotation = Vector3.FORWARD * _character.lean * camera_lean_carry

	if _mouse_escaped:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif in_inventory:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_hud.set_mouse_locked(not in_inventory and not _mouse_escaped)

	# Hotkeys.
	for key in _hotkey_binds:
		if Input.is_action_just_released(key):
			if _hotkeys.get(key) != null:
				var slot = _character.inventory.get_slot_with_item(_hotkeys[key])
				if slot != null:
					_character.manage_item_slot(slot)
			_hotkey_set_time = 0.0
		elif Input.is_action_pressed(key):
			_hotkey_set_time += delta
			if _hotkey_set_time > 0.3:
				_hotkeys[key] = _character.get_hand_slot().item
		elif _hotkeys.get(key) != null:
			if _character.inventory.get_slot_with_item(_hotkeys[key]) == null:
				_hotkeys[key] = null

func _screen_raycast(
	screen_position: Vector2, collision_mask: int, areas: bool,
	ignore: Array[RID] = []
) -> Dictionary:
	var space = get_world_3d().direct_space_state
	var from = _camera.project_ray_origin(screen_position)
	var to = from + (_camera.project_ray_normal(screen_position) * look_ray_length)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = collision_mask
	query.collide_with_areas = areas
	query.exclude = ignore

	var result = space.intersect_ray(query)
	result["from"] = from
	result["to"] = to
	return result

@rpc("call_local")
func _jump():
	_character.jumping = true

func _input(event):
	if event.is_action_pressed("escape"):
		self._mouse_escaped = not self._mouse_escaped

	if event.is_action_pressed("jump"):
		_jump.rpc()

	var interact_slot = _slot_target
	if _interact_target != null and interact_slot == null:
		interact_slot = _character.inventory.get_slot_with_item(_interact_target)

	if interact_slot and event.is_action_pressed("inventory_manage"):
		_character.manage_item_slot(interact_slot)

	if interact_slot and event.is_action_pressed("inventory_drop"):
		_character.drop_item_slot(interact_slot)

	if event.is_action_pressed("interact"):
		if _interact_target:
			_character.take_item(_interact_target)
		elif _character.object_interact_target and not _character.object_interact_target.default_interaction.is_null():
			_character.object_interact_target.default_interaction.call(_character)

	if event.is_action_pressed("reload"):
		_character.reload_active_item()

	if event.is_action_pressed("stow"):
		_character.stow_active_item()

	if event.is_action_pressed("inventory"):
		in_inventory = not in_inventory
		character.in_inventory = in_inventory
		_inventory_rotation = PI

	if event is InputEventMouseMotion and not _mouse_escaped and not in_inventory:
		_look_rotation = Vector3(-event.relative.y, -event.relative.x, 0) * MOUSE_SENSITIVITY

func is_authority():
	return _character.get_multiplayer_authority() == multiplayer.get_unique_id()
