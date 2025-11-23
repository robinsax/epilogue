class_name LootingAITrait extends AITrait

func vote_goal(character: Character, state: AIState, idle: bool) -> AIGoal:
	var closest: AIState.Knowledge = null
	var closest_distance: float = 1000.0
	for entry in state.get_item_knowledge():
		if character.inventory.get_available_slot_for(entry.node) == null:
			continue

		var node_distance = (entry.known_position - character.global_position).length()
		if node_distance < closest_distance:
			closest = entry
			closest_distance = node_distance

	if closest != null:
		return TakeItemAIGoal.create(closest, 0.2)

	var hand_slot = character.get_hand_slot()
	var best_hand_candidate: InventorySlot = null
	if hand_slot != null and hand_slot.item != null and hand_slot.item.hand_value > 0:
		best_hand_candidate = hand_slot

	for slot in character.inventory.all_slots():
		if slot.item == null:
			continue
		if slot == hand_slot:
			continue

		# Optimize inventory.
		var base_rank = slot.compatibility_rank_for(slot.item)
		var options = character.inventory.get_ranked_compatible_slots_for(slot.item)
		for option in options:
			if option.compatibility_rank_for(slot.item) > base_rank and option.is_available():
				return MoveItemSlotsAIGoal.create(slot, options[0], 0.2)

		# Prefer better items in hand.
		if best_hand_candidate == null or best_hand_candidate.item.hand_value < slot.item.hand_value:
			best_hand_candidate = slot

	if hand_slot != null and best_hand_candidate != null and best_hand_candidate != hand_slot:
		return MoveItemSlotsAIGoal.create(best_hand_candidate, hand_slot, 0.2)

	return null
