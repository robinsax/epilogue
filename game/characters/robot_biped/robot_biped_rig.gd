class_name RobotBipedRig extends RobotRig

@export var movement_lean_carry: float = 3.0
@export var input_lean_carry: float = 0.8
@export var crouch_lean: float = 0.9
@export var torso_move_bounce_amount: float = 0.09
@export var torso_move_bounce_speed: float = 0.3
@export var head_aim_tilt: float = 0.2

var _last_position: Vector3 = Vector3.ZERO
var _skeleton: Skeleton3D = null
var _ragdoll: PhysicalBoneSimulator3D = null
var _torso_bone: int = 0
var _head_bone: int = 0
var _move_time: float = 0
var _eye: Node3D = null

var main_hand_ik: ArmIK = null
var off_hand_ik: ArmIK = null
var front_position: Node3D = null

var torso_aim_influence: Basis = Basis.IDENTITY
var head_aim_influence: Basis = Basis.IDENTITY

func _ready():
	super._ready()
	_skeleton = $Skeleton
	_ragdoll = $Skeleton/Ragdoll
	main_hand_ik = $Skeleton/RArmIK
	off_hand_ik = $Skeleton/LArmIK
	_torso_bone = _skeleton.find_bone("B_Torso")
	_head_bone = _skeleton.find_bone("B_Head")
	front_position = $Skeleton/B_Torso/FrontPosition
	_eye = $Skeleton/B_Head/Eye

	_last_position = global_position

func _process(delta):
	super._process(delta)

	if character.dead:
		if not _ragdoll.active:
			_ragdoll.active = true
			_ragdoll.physical_bones_start_simulation()

		return

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
	if not local_last_move.is_zero_approx() and character.is_on_floor():
		var sin_time = _move_time / torso_move_bounce_speed
		sin_time -= int(sin_time)
		torso_offset += sin(sin_time * PI) * torso_move_bounce_amount
		_move_time += delta
	else:
		_move_time = 0

	var torso_rest_transform = _skeleton.get_bone_rest(_torso_bone)
	var torso_transform = Transform3D(
		torso_aim_influence * Basis(torso_rotation),
		torso_rest_transform.origin + Vector3.UP * torso_offset
	)
	_skeleton.set_bone_pose(_torso_bone, torso_transform)

	_eye.look_at(character.look_target)
	var head_look_basis = (
		Basis(Vector3.UP, _eye.global_rotation.y - global_rotation.y) *
		Basis(Vector3.BACK, _eye.global_rotation.x - global_rotation.x)
	)

	var head_rest_transform = _skeleton.get_bone_rest(_head_bone)
	var head_transform = Transform3D(
		head_look_basis * head_aim_influence,
		head_rest_transform.origin
	)
	_skeleton.set_bone_pose(_head_bone, head_transform)

func get_torso_position():
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_torso_bone).origin
