class_name RobotBipedRig extends RobotRig

@export var movement_lean_carry: float = 3.0
@export var input_lean_carry: float = 0.8
@export var crouch_lean: float = 0.9
@export var torso_move_bounce_amount: float = 0.09
@export var torso_move_bounce_speed: float = 0.3

var _last_position: Vector3 = Vector3.ZERO
var _skeleton: Skeleton3D = null
var _torso_bone: int = 0
var _move_time: float = 0

func _ready():
	super._ready()
	_skeleton = $Skeleton
	_torso_bone = _skeleton.find_bone("B_Torso")

	_last_position = global_position

func _process(delta):
	super._process(delta)

	var local_last_move = (global_position - _last_position).rotated(Vector3.UP, -global_rotation.y)
	_last_position = global_position

	var crouch_effect = 0
	if character.crouching:
		crouch_effect = crouch_lean

	var torso_rotation = (
		Quaternion(
			Vector3.LEFT,
			(-local_last_move.x * movement_lean_carry) + (character.lean * input_lean_carry)
		) +
		Quaternion(
			Vector3.FORWARD,
			(-local_last_move.z * movement_lean_carry) + crouch_effect
		)
	)
	var torso_offset = 0
	if not local_last_move.is_zero_approx():
		var sin_time = _move_time / torso_move_bounce_speed
		sin_time -= int(sin_time)
		torso_offset += sin(sin_time * PI) * torso_move_bounce_amount
		_move_time += delta
	else:
		_move_time = 0

	var torso_transform = Transform3D(torso_rotation)
	torso_transform.origin = Vector3.UP * torso_offset

	_skeleton.set_bone_global_pose(_torso_bone, torso_transform)
