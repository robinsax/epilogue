class_name Rig extends Node3D

# TODO: Used by GroundCharacter...
@export var crouch_reduction: float = 0.75

var character: Character = null

var _look_target_tracker: Node3D = null

func _ready():
	character = get_parent()
	_look_target_tracker = $LookTargetTracker

func _physics_process(delta):
	update_look(delta)

func get_perception_volumes() -> Array[PerceptionVolume]:
	return []

func update_look(delta):
	var look_target = character.look_target
	if not look_target.is_zero_approx():
		_look_target_tracker.global_position = look_target
	else:
		_look_target_tracker.position = Vector3.ZERO
