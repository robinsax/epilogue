class_name GroundCharacter extends Character

var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var crouch_slowdown: float = 0.75
@export var strafe_slowdown: float = 0.75
@export var leg_cripple_slowdown: float = 0.5
@export var look_zoom_slowdown: float = 0.75
@export var sprint_speedup: float = 1.5
@export var jump_velocity: float = 3
@export var crouch_energy_burn: float = 0.1
@export var sprint_energy_burn: float = 0.5
@export var jump_energy_burn: float = 2.0
@export var footstep_curve: Curve = null

@export var leg_cripple_hitboxes: Array[CharacterHitbox] = []

@export var jumping: bool = false
@export var crouching: bool = false
@export var sprinting: bool = false
@export var lean: float = 0

var _collider_base_height: float = 0
var _base_rig_y: float = 0
var _jump_move_direction_lock: Vector3 = Vector3.ZERO

var footsteps_audio: ClippedAudioPlayer
var _footstep_time: float

func _ready():
	super._ready()
	footsteps_audio = $Footsteps

	bound_to_ground = true

	_base_rig_y = rig.position.y
	_collider_base_height = collider.shape.height

func _process(delta):
	super._process(delta)

	if _footstep_time > 0.0:
		_footstep_time -= delta
	if not dead and not move_direction.is_zero_approx() and shell.is_on_floor():
		if _footstep_time <= 0.0:
			footsteps_audio.play_random_clip(0, 4)
			_footstep_time = 1.0 / footstep_curve.sample(get_current_speed())

	if crouching:
		collider.shape.height = _collider_base_height * rig.crouch_reduction
		energy -= crouch_energy_burn * delta
	else:
		collider.shape.height = _collider_base_height

	if sprinting:
		energy -= sprint_energy_burn * delta

	_update_rig_offset()

func _update_rig_offset():
	return
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
		energy -= jump_energy_burn

	super.update_velocity(delta)

func get_current_speed():
	var current = super.get_current_speed()

	if crouching:
		current *= crouch_slowdown
	var strafing = move_direction.z >= 0
	if strafing:
		current *= strafe_slowdown
	if look_zoomed:
		current *= look_zoom_slowdown

	for hitbox in leg_cripple_hitboxes:
		if hitbox.current_hitpoints <= 0.0:
			current *= leg_cripple_slowdown
			break

	if not crouching and not strafing and not look_zoomed and sprinting:
		current *= sprint_speedup

	return current
