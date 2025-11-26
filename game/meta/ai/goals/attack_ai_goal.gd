class_name AttackAIGoal extends AIGoal

var target_knowledge: AIState.Knowledge = null

static func create(target: AIState.Knowledge, priority: float) -> AttackAIGoal:
	var instance = AttackAIGoal.new()
	instance.target_knowledge = target
	instance.priority = priority

	return instance

func debug_info() -> String:
	return super.debug_info() + ": " + target_knowledge.node.name

func debug_target() -> Vector3:
	return target_knowledge.node.global_position

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	if target_knowledge.node.dead:
		done = true
		return

	if target_knowledge.age > 2.0:
		if (target_knowledge.known_position - character.global_position).length() > 5.0:
			state.push_goal(ReachTargetAIGoal.create(target_knowledge.known_position, priority, {
				"close_enough": 3.0
			}))
		else:
			done = true
		return

	if not _try_use_gun(character, driver, state):
		if character.get_hand_slot().item is GunItem:
			character.stow_active_item()

	var real_delta = character.global_position - target_knowledge.node.global_position
	var real_distance = real_delta.length()
	if real_distance < 1.3:
		if real_distance > 0.7:
			driver.move_towards(target_knowledge.node.global_position)
		else:
			driver.look_towards(target_knowledge.node.global_position)
		character.aiming = true
		character.firing = true
	else:
		state.push_goal(ReachTargetAIGoal.create(target_knowledge.known_position, priority, {
			"close_enough": 1.0
		}))

func _try_use_gun(character: Character, driver: CharacterDriver, state: AIState) -> bool:
	var hand_slot = character.get_hand_slot()
	if not hand_slot:
		return false

	if hand_slot.item == null or not hand_slot.item is GunItem:
		var available_gun = character.inventory.get_slot_with_item_tag_best_hand_value("gun")
		if available_gun != null and available_gun.item.magazine_well.item != null:
			state.push_goal(MoveItemSlotsAIGoal.create(available_gun, hand_slot, priority))
			return true

		return false

	var gun: GunItem = hand_slot.item
	if gun.magazine_well.is_available() and not gun.is_chambered():
		if not gun.reload_as_active(character):
			return false
		else:
			return true

	character.aiming = true
	driver.look_towards(target_knowledge.known_position)

	character.look_target = target_knowledge.known_position
	character.aim_target = target_knowledge.known_position

	if character.can_perform_actions():
		character.firing = true
	return true

func apply_inactive(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	character.aiming = true
