class_name AIGoal extends Object

signal finished()

var done: bool = false
var priority: float = 0.0

func debug_info() -> String:
	return get_script().get_global_name()

func debug_target() -> Vector3:
	return Vector3.ZERO

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	pass

func apply_inactive(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	pass
