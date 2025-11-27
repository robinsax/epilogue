class_name BugRig extends Rig

var _skeleton: Skeleton3D
var _fly_time: float
var _left_leg_ik: LegIK
var _right_leg_ik: LegIK
var _left_wing_bone: int
var _right_wing_bone: int
var _right_wing_rest: Transform3D
var _left_wing_rest: Transform3D

func _ready():
	super._ready()

	_skeleton = $Skeleton
	_left_leg_ik = $Skeleton/LFLIK
	_right_leg_ik = $Skeleton/RFLIK
	_right_wing_bone = _skeleton.find_bone("RWing")
	_right_wing_rest = _skeleton.get_bone_global_pose(_right_wing_bone)
	_left_wing_bone = _skeleton.find_bone("LWing")
	_left_wing_rest = _skeleton.get_bone_global_pose(_left_wing_bone)

func _process(delta: float) -> void:
	if character.dead:
		return

	if character.flying:
		_fly_time += delta
		_set_wing_pose(_right_wing_bone, _right_wing_rest)
		_set_wing_pose(_left_wing_bone, _left_wing_rest, 0.5)

func _set_wing_pose(wing: int, rest: Transform3D, offset: float = 0.0):
	var sin_value = sin((_fly_time + offset) * 30.0)
	var this_pose = rest\
		.rotated(Vector3.UP, 0.1 + (sin_value * PI * 0.1))\
		.rotated(Vector3.LEFT, sin_value * PI * 0.1)

	_skeleton.set_bone_global_pose(wing, this_pose)

func get_ungrounded_leg_ik_target(leg: LegIK):
	var domain = _fly_time * 10.0
	if leg == _left_leg_ik:
		domain += PI * 0.5

	return leg.global_position + Vector3(0.0, sin(domain) * 0.1, 0.0)

func get_leg_ik_step_distance():
	return 0.05
