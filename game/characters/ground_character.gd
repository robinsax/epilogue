class_name GroundCharacter extends Character

var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var crouch_slowdown: float = 0.75
@export var strafe_slowdown: float = 0.75
@export var sprint_speedup: float = 1.5
@export var jump_velocity: float = 3

@export var jumping: bool = false
@export var crouching: bool = false
@export var sprinting: bool = false
@export var lean: float = 0

var _collider_base_height: float = 0
var _base_rig_y: float = 0
var _jump_move_direction_lock: Vector3 = Vector3.ZERO

func _ready():
	super._ready()
	_base_rig_y = rig.position.y
	_collider_base_height = collider.shape.height

func _process(delta):
	super._process(delta)

	if crouching:
		collider.shape.height = _collider_base_height * rig.crouch_reduction
	else:
		collider.shape.height = _collider_base_height

	_update_rig_offset()

func _update_rig_offset():
	# Shift rig to allow leg IK on slopes.
	var floor_angle = shell.get_floor_angle()
	if abs(floor_angle - (PI / 2)) > 0.01:
		# Not in air.
		rig.position.y = _base_rig_y - abs(floor_angle * 0.1)
	else:
		rig.position.y = _base_rig_y

func update_velocity(delta):
	var on_floor = shell.is_on_floor()
	if not on_floor:
		move_direction = _jump_move_direction_lock.rotated(Vector3.UP, -global_rotation.y)
		velocity.y -= _gravity * delta

	if jumping and on_floor:
		velocity.y = jump_velocity
		_jump_move_direction_lock = move_direction.rotated(Vector3.UP, global_rotation.y)

	super.update_velocity(delta)

func get_current_speed():
	var current = super.get_current_speed()

	if crouching:
		current *= crouch_slowdown

	if move_direction.z >= 0:
		current *= strafe_slowdown
	elif sprinting:
		current *= sprint_speedup

	return current

func get_leg_ik_step_distance():
	return get_current_speed() * 2.0
