class_name MoveItemSlotsAIGoal extends AIGoal

var from_slot: InventorySlot = null
var to_slot: InventorySlot = null
var _started: bool = false
var _after_time: float = 0.0

static func create(from_slot: InventorySlot, to_slot: InventorySlot, priority: float) -> MoveItemSlotsAIGoal:
	var instance = MoveItemSlotsAIGoal.new()
	instance.priority = priority
	instance.from_slot = from_slot
	instance.to_slot = to_slot
	instance._after_time = 0.5

	return instance

func debug_info() -> String:
	return super.debug_info() + ": " + from_slot.key + " -> " + to_slot.key

func apply_active(character: Character, driver: CharacterDriver, state: AIState, delta: float):
	if not character.can_perform_actions():
		return

	if not _started:
		character.move_item_slots(from_slot, to_slot)
		_started = true
		return

	_after_time -= delta
	if _after_time <= 0.0:
		done = true
