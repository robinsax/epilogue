class_name ReachTargetAIGoal extends AIGoal

var _node: Node3D = null
var _close_enough: float = 1.0
var _wait_after: float = 1.0
var _position: Vector3 = Vector3.ZERO
var _remaining_distance: float = 0.0

static func create(destination: Variant, priority: float, ext: Dictionary) -> ReachTargetAIGoal:
	var instance = ReachTargetAIGoal.new()
	instance.priority = priority

	if destination is Node3D:
		instance._node = destination
	else:
		instance._position = destination
	instance._close_enough = ext.get("close_enough", 1.0)
	instance._wait_after = ext.get("wait_after", 0.0)

	return instance

func debug_info() -> String:
	return super.debug_info() + ": " + str(_remaining_distance)

func _get_position() -> Vector3:
	if _node != null:
		return _node.global_position
	return _position

func debug_target() -> Vector3:
	return _get_position()

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	var position = _get_position()
	if _node != null:
		state.fixate(_node, 0.1)

	var move_delta = character.feet_position.global_position - position
	move_delta.y = 0.0
	_remaining_distance = move_delta.length()
	if _remaining_distance <= _close_enough:
		if _wait_after > 0.0:
			_wait_after -= delta
		else:
			done = true
		return

	if (character.nav_agent.target_position - position).length() > 0.5:
		character.nav_agent.target_position = position

	if character.nav_agent.get_current_navigation_path().size() <= 1:
		var final_miss = (character.nav_agent.get_final_position() - position).length()
		if final_miss > _close_enough:
			print("Abort ReachTarget, final miss ", final_miss)
			# Give up.
			done = true
			return

	var next = character.nav_agent.get_next_path_position()
	driver.move_towards(next)
	return false
