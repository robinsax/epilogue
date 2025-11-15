class_name PlayerPossession extends Possession

var MOUSE_SENSITIVITY = 0.006

@export var camera_lean_carry: float = 0.15
@export var look_ray_length: float = 30.0

var _camera_arm: SpringArm3D = null
var _camera: Camera3D = null
var _character: Character = null

var _mouse_escaped = false

func _ready():
	super._ready()
	_camera_arm = $CameraArm
	_camera = $CameraArm/Camera
	_character = get_parent()

	if is_authority():
		_camera.set_current(true)

func _process(delta):
	if not is_authority():
		return

	_camera_arm.rotate_x(_character.look_rotation.x)

	_character.move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_character.look_rotation = Vector3()
	_character.jumping = false

	if _character is GroundCharacter:
		_character.crouching = Input.is_action_pressed("crouch")

		_character.lean = Input.get_axis("lean_right", "lean_left")
		# TODO: Needs dynamic conf.
		_camera.rotation = Vector3.FORWARD * _character.lean * camera_lean_carry

	if _mouse_escaped:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var space = get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2.0
	var from = _camera.project_ray_origin(screen_center)
	var to = from + _camera.project_ray_normal(screen_center) * look_ray_length

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	if "position" in result:
		_character.look_target = result.position
	else:
		_character.look_target = to

@rpc("call_local")
func _jump():
	_character.jumping = true

func _input(event):
	if event.is_action_pressed("escape"):
		self._mouse_escaped = not self._mouse_escaped

	if event.is_action_pressed("jump"):
		_jump.rpc()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		character.look_rotation = Vector3(-event.relative.y, -event.relative.x, 0) * MOUSE_SENSITIVITY

func is_authority():
	return _character.get_multiplayer_authority() == multiplayer.get_unique_id()
