class_name LegIK extends SkeletonIK3D

@export var other_legs: Array[LegIK]
@export var owner_colliders: Array[CollisionObject3D]
@export var tolerance: float = 0.25
@export var step_vertical: float = 0.2
@export var step_duration: float = 0.1
@export var ground_check_offset: float = 1.0
@export var ground_check_float_tolerance: float = 0.2

var _character: GroundCharacter = null

var _target: Node3D = null
var _target_position: Vector3 = Vector3.ZERO
var _last_position: Vector3 = Vector3.ZERO

var stepping_to: Vector3 = Vector3.ZERO
var _stepping_from: Vector3 = Vector3.ZERO
var _step_time: float = 0

var _grounded: bool = false

func _ready():
	_target = $Target
	_target_position = _target.global_position
	_last_position = global_position

	_character = Character.find_parent_character(self)

	start()

func _physics_process(delta):
	if _character.dead:
		stop()
		return

	_target.global_position = _target_position

	if not stepping_to.is_zero_approx() and _grounded:
		_step_time += delta
		var step_progress = _step_time / step_duration
		_target_position = _stepping_from + ((stepping_to - _stepping_from) * step_progress)
		
		var this_step_distance = (_stepping_from - stepping_to).length()
		_target_position += Vector3.UP * sin(step_progress * PI) * step_vertical * this_step_distance
		if _step_time > step_duration:
			stepping_to = Vector3.ZERO
	else:
		_maybe_step(delta)

	if not _grounded:
		_target_position = global_position + (Vector3.UP * 0.2)
	
func _maybe_step(delta):
	var last_move = global_position - _last_position
	_last_position = global_position

	last_move.y = 0
	var step_distance = _character.get_leg_ik_step_distance()
	var ideal_next_step = global_position + (last_move * step_distance)

	# Raycast for Y coordinate.
	var space = get_world_3d().direct_space_state
	var to = ideal_next_step - (Vector3.UP * ground_check_float_tolerance)
	var from = ideal_next_step + (Vector3.UP * ground_check_offset)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = _character.shell.get_collision_mask()
	for collider in owner_colliders:
		query.exclude.push_back(collider.get_rid())

	var was_grounded = _grounded

	var result = space.intersect_ray(query)
	if "position" in result:
		ideal_next_step.y = result.position.y
	else:
		_grounded = false
		return

	var distance = (ideal_next_step - _target_position).length()
	if distance < tolerance and was_grounded:
		return

	for other in other_legs:
		if not other.stepping_to.is_zero_approx():
			return

	stepping_to = ideal_next_step
	_stepping_from = global_position
	_step_time = 0
	_grounded = true
