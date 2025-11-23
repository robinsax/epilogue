class_name AIPossession extends Possession

@export var ai_enabled: bool = true

var _state: AIState = null
var _character: Character = null
var _driver: CharacterDriver = null
var _traits: Array[AITrait] = []
var _start_time: float = 0.0

var _debug_label: Label3D = null
var _debug_target: Node3D = null

func _ready():
	_character = get_parent()
	_debug_label = $Label3D
	_debug_target = $Target

	_start_time = 2.0

	_driver = CharacterDriver.get_for_character(_character)
	_driver.bind(_character, self)

	_state = AIState.new()

	_traits = []
	for node in get_children(true):
		if node is AITrait:
			_traits.push_back(node)

func _process(delta):
	if not ai_enabled:
		return

	if _start_time > 0.0:
		_start_time -= delta
		return

	if _character.dead:
		return

	_driver.reset_update()

	var is_idle = _state.goal_stack.size() == 0
	var best_new_vote: AIGoal = null
	for item in _traits:
		var vote = item.vote_goal(_character, _state, is_idle)
		if vote == null:
			continue

		if best_new_vote == null or vote.priority > best_new_vote.priority:
			best_new_vote = vote

	var apply_new = (
		best_new_vote and
		(is_idle or _state.goal_stack[_state.goal_stack.size() - 1].priority < best_new_vote.priority)
	)
	if apply_new:
		_state.goal_stack.push_back(best_new_vote)

	var goal_count = _state.goal_stack.size()
	for i in goal_count - 1:
		_state.goal_stack[i].apply_inactive(_character, _driver, _state, delta)

	_debug_label.text = ""
	for goal in _state.goal_stack:
		_debug_label.text += goal.debug_info() + "\n"

	if goal_count > 0:
		var active = _state.goal_stack[goal_count - 1]
		_debug_target.global_position = active.debug_target()
		active.apply_active(_character, _driver, _state, delta)
	else:
		_debug_target.global_position = Vector3.ZERO

	_driver.cosmetic_update(_state)
	_state.update(_character, delta)
