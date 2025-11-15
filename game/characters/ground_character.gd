class_name GroundCharacter extends Character

var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var crouch_slowdown: float = 0.5
@export var strafe_slowdown: float = 0.5
@export var jump_velocity: float = 3

@export var jumping: bool = false
@export var crouching: bool = false
@export var lean: float = 0

var _collider_base_height: float = 0
var _jump_move_direction_lock: Vector2 = Vector2.ZERO

func _ready():
	super._ready()

	_collider_base_height = collider.shape.height

func _process(delta):
	super._process(delta)

	if crouching:
		collider.shape.height = _collider_base_height * rig.crouch_reduction
	else:
		collider.shape.height = _collider_base_height

func _physics_process(delta):
	super._physics_process(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	if jumping and is_on_floor():
		velocity.y = jump_velocity
		_jump_move_direction_lock = move_direction

func update_velocity(delta):
	if not is_on_floor():
		move_direction = _jump_move_direction_lock

	super.update_velocity(delta)

func get_current_speed():
	var current = super.get_current_speed()

	if crouching:
		current *= crouch_slowdown

	if move_direction.y >= 0:
		current *= strafe_slowdown

	return current

func get_leg_ik_step_distance():
	return get_current_speed() * 2.0
