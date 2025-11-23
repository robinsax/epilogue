class_name TakeItemAIGoal extends AIGoal

var item: Item = null
var known_position: Vector3 = Vector3.ZERO
var is_direct: bool = false
var _after_time: float = 0.0
var _has_taken: bool = false

static func create(target: Variant, priority: float) -> TakeItemAIGoal:
	var instance = TakeItemAIGoal.new()
	instance.priority = priority
	instance._after_time = 0.5
	if target is AIState.Knowledge:
		instance.item = target.node
		instance.known_position = target.known_position
	else:
		instance.item = target
		instance.known_position = target.global_position
		instance.is_direct = true

	return instance

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	if is_direct:
		state.fixate(item, 0.1)

	var dest_distance = (known_position - character.global_position).length()
	var item_distance = (item.global_position - character.global_position).length()
	if dest_distance > character.interact_reach:
		state.push_goal(ReachTargetAIGoal.create(known_position, priority, {
			"close_enough": character.interact_reach - 0.25
		}))
		return

	if not _has_taken and item_distance <= character.interact_reach:
		character.take_item(item)
		_has_taken = true
		return

	if _has_taken and character.can_perform_actions():
		_after_time -= delta
		if _after_time <= 0.0:
			done = true
