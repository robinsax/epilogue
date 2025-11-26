class_name RobotBipedRig extends RobotRig

@export var movement_lean_carry: float = 3.0
@export var input_lean_carry: float = 0.8
@export var crouch_lean: float = 0.9
@export var torso_move_bounce_amount: float = 0.09
@export var torso_move_bounce_speed: float = 0.3
@export var head_aim_tilt: float = 0.2

var _last_position: Vector3
var _skeleton: Skeleton3D
var _ragdoll: PhysicalBoneSimulator3D
var _torso_bone: int
var _head_bone: int
var _move_time: float

var fists_left_anchor: Node3D
var fists_right_anchor: Node3D
var status_check_anchor: Node3D
var eye: Node3D
var main_hand_ik: ArmIK
var off_hand_ik: ArmIK
var front_position: Node3D

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
	eye = $Skeleton/B_Torso/Eye

	fists_left_anchor = $Skeleton/B_Torso/FistsLeft
	fists_right_anchor = $Skeleton/B_Torso/FistsRight
	status_check_anchor = $Skeleton/B_Torso/StatusCheck

	_last_position = global_position

func _physics_process(delta):
	if character.update_culled:
		return

	super._physics_process(delta)

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
	if not local_last_move.is_zero_approx() and character.shell.is_on_floor():
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

	var look_target = character.look_target
	if character.in_inventory and look_target.y > eye.global_position.y - 0.2:
		look_target = eye.global_position + Vector3.FORWARD.rotated(Vector3.UP, global_rotation.y)
	if character.checking_status:
		look_target = status_check_anchor.global_position
	var local_target = (
		(eye.global_position - look_target).rotated(Vector3.UP, -_skeleton.global_rotation.y)
	)
	if local_target.x < 0.0:
		eye.look_at(look_target, Vector3.UP)
	var head_look_basis = eye.basis * Basis(Vector3.UP, PI / 2)

	var head_rest_transform = _skeleton.get_bone_rest(_head_bone)
	var head_transform = Transform3D(
		head_look_basis * head_aim_influence,
		head_rest_transform.origin
	)
	_skeleton.set_bone_pose(_head_bone, head_transform)

func get_torso_position():
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_torso_bone).origin
