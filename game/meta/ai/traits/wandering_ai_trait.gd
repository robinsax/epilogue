class_name WanderingAITrait extends AITrait

func vote_goal(character: Character, state: AIState, idle: bool) -> AIGoal:
	if not idle:
		return null

	var to = (
		character.global_position +
		(Vector3.FORWARD * (0.2 + randf()) * 10.0).rotated(Vector3.UP, randf() * PI * 2.0)
	)
	return ReachTargetAIGoal.create(to, 0.1, {
		"wait_after": 0.5 + (randf() * 3.0)
	})
