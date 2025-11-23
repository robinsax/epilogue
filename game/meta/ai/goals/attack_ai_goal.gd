class_name AttackAIGoal extends AIGoal

var target_knowledge: AIState.Knowledge = null

static func available(character: Character) -> bool:
	var gun_slot = character.inventory.get_slot_with_item_tag_best_hand_value("gun")
	if gun_slot == null:
		return false

	var mag_slot = character.inventory.get_slot_with_item_tag(gun_slot.item.magazine_well.required_tag)
	return mag_slot != null

static func create(target: AIState.Knowledge, priority: float) -> AttackAIGoal:
	var instance = AttackAIGoal.new()
	instance.target_knowledge = target
	instance.priority = priority

	return instance

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	if target_knowledge.node.dead:
		done = true
		return

	var hand_slot = character.get_hand_slot()
	if not hand_slot:
		done = true
		return

	if hand_slot.item == null or not hand_slot.item is GunItem:
		var available_gun = character.inventory.get_slot_with_item_tag_best_hand_value("gun")
		if available_gun != null:
			state.push_goal(MoveItemSlotsAIGoal.create(available_gun, hand_slot, priority))
			return

		done = true
		return

	var gun: GunItem = hand_slot.item
	if gun.magazine_well.is_available() and not gun.is_chambered():
		if not gun.reload_as_active(character):
			done = true
			return
		else:
			return

	character.aiming = true
	character.look_at(target_knowledge.known_position)
	character.rotation.x = 0
	character.rotation.z = 0

	if target_knowledge.age > 2.0:
		if (target_knowledge.known_position - character.global_position).length() > 5.0:
			state.push_goal(ReachTargetAIGoal.create(target_knowledge.known_position, priority, {
				"close_enough": 3.0
			}))
		else:
			done = true
		return

	character.look_target = target_knowledge.known_position
	character.aim_target = target_knowledge.known_position

	if character.can_perform_actions():
		character.firing = true

func apply_inactive(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	character.aiming = true
