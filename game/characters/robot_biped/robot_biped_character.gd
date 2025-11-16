class_name RobotBipedCharacter extends GroundCharacter

var _typed_rig: RobotBipedRig = null
var _main_hand_slot: InventorySlot = null

func _ready():
	super._ready()

	_typed_rig = rig
	_main_hand_slot = inventory.get_slot("rhand")

func take_item(item: Item):
	if not _main_hand_slot.is_item_compatible(item):
		# Can't take because can't hold in hand.
		return

	var anim_chain = AnimChain.new()

	if not _main_hand_slot.is_available():
		# Must clear hand slot.
		var active_dest_slot = inventory.get_available_slot_for(item)

		var free_hand = func ():
			_move_item_to_slot(_main_hand_slot.item, active_dest_slot, anim_chain.next)
		anim_chain.add(free_hand)

	var take_to_hand = func ():
		_move_item_to_slot(item, _main_hand_slot, anim_chain.next)
	anim_chain.add(take_to_hand)

	anim_chain.next.call()

func stow_main_hand_item():
	if _main_hand_slot.item == null:
		return

	var to_slot = inventory.get_available_slot_for(_main_hand_slot.item)
	_move_item_to_slot(_main_hand_slot.item, to_slot, Callable())

func _move_item_to_slot(item: Item, slot: InventorySlot, then: Callable):
	var anim_chain = AnimChain.new()

	if _main_hand_slot.item != item:
		var move_hand_to_item = func ():
			_typed_rig.main_hand_ik.reach_to(item.global_position, anim_chain.next)
		anim_chain.add(move_hand_to_item)

	if slot != _main_hand_slot:
		var move_hand_to_target = func ():
			var to_position = _typed_rig.front_position.global_position
			if slot != null:
				to_position = slot.global_position
			_typed_rig.main_hand_ik.reach_to(to_position, anim_chain.next)
		anim_chain.add(move_hand_to_target)

	var finalize = func ():
		var attachment = ""
		if slot != null:
			attachment = inventory.get_attachment_string(slot)
		item.update_attachment.rpc(attachment)

		if not then.is_null():
			then.call()
	anim_chain.add(finalize)

	anim_chain.next.call()
