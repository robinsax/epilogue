class_name AggressiveAITrait extends AITrait

func vote_goal(character: Character, state: AIState, idle: bool) -> AIGoal:
	if state.misc.get("attacking", false):
		return null

	for target in state.get_character_knowledge():
		if not target.node.dead:
			var attack = AttackAIGoal.create(target, 0.9)
			state.misc["attacking"] = true
			character.say("You\'re discontinued!")
			attack.finished.connect(func (): state.misc.erase("attacking"))
			return attack

	return null
