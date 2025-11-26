class_name AIState extends Object

class Knowledge:
	var node: Node3D
	var known_position: Vector3
	var age: float

var goal_stack: Array[AIGoal] = []
var knowledge: Array[Knowledge] = []
var fixation: Node3D = null
var fixation_weight: float = 0.0
var misc: Dictionary = {}

func update(character: Character, delta: float):
	var remove_goals: Array[AIGoal] = []
	for goal in goal_stack:
		if goal.done:
			remove_goals.push_back(goal)

	for goal in remove_goals:
		goal.finished.emit()
		goal_stack.remove_at(goal_stack.find(goal))

	for entry in knowledge:
		entry.age += delta

	for node in character.get_perception_volumes_contents():
		if node is Item:
			if node.attachment.length() == 0:
				add_knowledge(node)
			else:
				remove_knowledge(node)
		if node is HiFiCharacterShell or node is LoFiCharacterShell:
			var target_character = node.get_children()[0]
			if target_character != character:
				add_knowledge(target_character)

	fixation = null
	fixation_weight = 0.0

func add_knowledge(node: Node3D):
	for check in knowledge:
		if check.node == node:
			check.known_position = node.global_position
			check.age = 0.0
			return

	var instance = Knowledge.new()
	instance.node = node
	instance.known_position = node.global_position
	instance.age = 0.0

	knowledge.push_back(instance)

func remove_knowledge(node: Node3D):
	for i in knowledge.size():
		if knowledge[i].node == node:
			knowledge.remove_at(i)
			return

func get_item_knowledge() -> Array[Knowledge]:
	var entries: Array[Knowledge] = []
	for entry in knowledge:
		if entry.node is Item:
			entries.push_back(entry)

	return entries

func get_character_knowledge() -> Array[Knowledge]:
	var entries: Array[Knowledge] = []
	for entry in knowledge:
		if entry.node is Character:
			entries.push_back(entry)

	return entries

func push_goal(goal: AIGoal):
	goal_stack.push_back(goal)

func fixate(target: Node3D, weight: float):
	if weight < fixation_weight:
		return

	fixation = target
	fixation_weight = weight
