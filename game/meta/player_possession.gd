class_name PlayerPossession extends Possession

var MOUSE_SENSITIVITY = 0.006

@export var camera_lean_carry: float = 0.15
@export var look_ray_length: float = 30.0
@export var camera_sprint_fov: float = 72.0
@export var inventory_rotate_rate: float = 360.0
@export var inventory_camera_arm_length: float = 1.2

var _camera_arm: SpringArm3D = null
var _camera: Camera3D = null
var _character: Character = null
var _hud_interact: Label = null
var _hud_crosshair: Control = null

var _interact_target: Node3D = null
var _in_inventory: bool = false
var _inventory_rotation: float = 0
var _mouse_escaped: bool = false
var _base_camera_fov: float = 0
var _base_camera_arm_position: Vector3 = Vector3.ZERO
var _base_camera_arm_length: float = 0

func _ready():
	super._ready()
	_character = get_parent()
	_camera_arm = $CameraArm
	_camera = $CameraArm/Camera
	_hud_interact = $CameraArm/Camera/HUD/InteractPrompt
	_hud_crosshair = $CameraArm/Camera/HUD/Crosshair

	_base_camera_fov = _camera.fov
	_base_camera_arm_length = _camera_arm.spring_length
	_base_camera_arm_position = _camera_arm.position

	if is_authority():
		_camera.set_current(true)

func _process(delta):
	if not is_authority():
		return

	var look_cast_screen_position = Vector2.ZERO

	var was_in_inventory = _in_inventory
	_in_inventory = Input.is_action_pressed("inventory")
	_hud_crosshair.visible = not _in_inventory
	if _in_inventory:
		if not was_in_inventory:
			_inventory_rotation = PI
		_character.look_rotation = Vector3()

		if Input.is_action_pressed("lean_left"):
			_inventory_rotation += inventory_rotate_rate * delta
		elif Input.is_action_pressed("lean_right"):
			_inventory_rotation -= inventory_rotate_rate * delta

		_camera_arm.spring_length = inventory_camera_arm_length
		_camera_arm.position = Vector3.ZERO
		_camera_arm.rotation = Vector3(0.0, _inventory_rotation, 0.0)

		look_cast_screen_position = get_viewport().get_mouse_position()
	else:
		_inventory_rotation = 0

		_camera_arm.spring_length = _base_camera_arm_length
		_camera_arm.position = _base_camera_arm_position
		_camera_arm.rotation.y = 0
		_camera_arm.rotate_x(_character.look_rotation.x)

		if _character is GroundCharacter:
			_character.crouching = Input.is_action_pressed("crouch")
			_character.sprinting = Input.is_action_pressed("sprint")

			_character.lean = Input.get_axis("lean_right", "lean_left")

		look_cast_screen_position = get_viewport().size / 2.0

	_character.move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_character.look_rotation = Vector3()
	_character.jumping = false

	if _character.sprinting:
		_camera.fov = camera_sprint_fov
	else:
		_camera.fov = _base_camera_fov
	if _character is GroundCharacter:
		_camera.rotation = Vector3.FORWARD * _character.lean * camera_lean_carry

	if _mouse_escaped or _in_inventory:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var space = get_world_3d().direct_space_state
	var from = _camera.project_ray_origin(look_cast_screen_position)
	var to = from + _camera.project_ray_normal(look_cast_screen_position) * look_ray_length

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2
	var result = space.intersect_ray(query)
	if "position" in result:
		_character.look_target = result.position
	else:
		_character.look_target = to

	_interact_target = null
	if "collider" in result:
		var hit = result.collider
		if hit is Item:
			_interact_target = hit

	if _interact_target:
		_hud_interact.text = _interact_target.label
	else:
		_hud_interact.text = ""

@rpc("call_local")
func _jump():
	_character.jumping = true

func _input(event):
	if event.is_action_pressed("escape"):
		self._mouse_escaped = not self._mouse_escaped

	if event.is_action_pressed("jump"):
		_jump.rpc()

	if _interact_target and event.is_action_pressed("interact"):
		_character.take_item(_interact_target)

	# TODO: Yukky.
	if event.is_action_pressed("stow") and _character is RobotBipedCharacter:
		_character.stow_main_hand_item()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		character.look_rotation = Vector3(-event.relative.y, -event.relative.x, 0) * MOUSE_SENSITIVITY

func is_authority():
	return _character.get_multiplayer_authority() == multiplayer.get_unique_id()
