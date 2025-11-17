class_name RobotBipedCharacter extends GroundCharacter

var _typed_rig: RobotBipedRig = null
var _main_hand_slot: InventorySlot = null

var _hand_busy: bool = false

func _ready():
	super._ready()
	_typed_rig = rig
	_main_hand_slot = inventory.get_slot("rhand")

func _process(delta):
	super._process(delta)

	_update_hand_item_state()

func _update_hand_item_state():
	if _hand_busy or not _main_hand_slot.item:
		return

	var root_hand_position = Vector3.ZERO
	var root_off_hand_position = Vector3.ZERO
	var torso_aim = Basis.IDENTITY
	var head_aim = Basis.IDENTITY

	rig.rotation = Vector3.ZERO

	var item = _main_hand_slot.item
	item.current_slot_parenting.update_rotation = false
	if item is GunItem:
		var low_anchor = find_child(item.character_low_ready_anchor, true, false)
		var anchor_position = low_anchor.global_position
		item.global_rotation = low_anchor.global_rotation
		item.global_position = anchor_position

		item.current_slot_parenting.update_position = false
		if aiming:
			# Compute aim:
			# 1. Apply part of the rotation as torso influence.
			var torso_aim_direction = (aim_target - _typed_rig.get_torso_position()).normalized()

			var horizontal_distance = Vector2(torso_aim_direction.z, torso_aim_direction.x).length()
			var pitch = atan2(torso_aim_direction.y, horizontal_distance)

			torso_aim = (
				Basis(Vector3.BACK, pitch) *
				Basis(Vector3.UP, -item.biped_dominant_shoulder_push)
			)

			# 2. Compute anchor point aligned with aim point based off the aim anchor.
			var aim_center_position =  find_child(item.character_aim_anchor, true, false).global_position
			var anchor_aim_direction = (aim_target - aim_center_position).normalized()

			anchor_position = aim_center_position + (anchor_aim_direction * item.biped_aim_radius)

			# 3. Align gun.
			var gun_aim_direction = (aim_target - item.global_position).normalized()
			var gun_basis = Basis()
			gun_basis.x = -gun_aim_direction
			gun_basis.z = gun_basis.x.cross(Vector3.UP).normalized()
			gun_basis.y = gun_basis.z.cross(gun_basis.x).normalized()

			item.global_position = anchor_position - (gun_basis * item.aim_anchor.position)
			item.current_slot_parenting.update_position = false
			item.basis = gun_basis

			root_off_hand_position = item.offhand_grip.global_position
			anchor_position = item.grip.global_position
			
			rig.rotation = Vector3.UP * -item.biped_body_rotation

			head_aim = Basis(Vector3.LEFT, -0.5)

		root_hand_position = item.grip.global_position

	_typed_rig.torso_aim_influence = torso_aim
	_typed_rig.head_aim_influence = head_aim
	_typed_rig.main_hand_ik.set_root_global_position(root_hand_position)
	_typed_rig.off_hand_ik.set_root_global_position(root_off_hand_position)

func get_look_cast_ignore_rids() -> Array[RID]:
	var rids = super.get_look_cast_ignore_rids()

	if _main_hand_slot.item:
		rids.push_back(_main_hand_slot.item.get_rid())

	return rids

func take_item(item: Item):
	if not _main_hand_slot.is_item_compatible(item) or _hand_busy:
		return
	_hand_busy = true

	var anim_chain = AnimChain.new()

	_chain_ensure_main_hand_clear(anim_chain)

	var take_to_hand = func ():
		_move_item_to_slot(item, _main_hand_slot, anim_chain.next)
	anim_chain.add(take_to_hand)

	var clear = func ():
		_hand_busy = false
		anim_chain.next.call()
	anim_chain.add(clear)

	anim_chain.next.call()

func drop_item_slot(target_slot: InventorySlot):
	if target_slot.item == null or _hand_busy:
		return
	_hand_busy = true

	var item = target_slot.item
	var anim_chain = AnimChain.new()

	if target_slot != _main_hand_slot:
		_chain_ensure_main_hand_clear(anim_chain)

	var take_to_hand = func ():
		_move_item_to_slot(item, _main_hand_slot, anim_chain.next)
	anim_chain.add(take_to_hand)

	var drop = func ():
		_move_item_to_slot(item, null, anim_chain.next)
	anim_chain.add(drop)

	var clear = func ():
		_hand_busy = false
		anim_chain.next.call()
	anim_chain.add(clear)

	anim_chain.next.call()

func manage_item_slot(target_slot: InventorySlot):
	if target_slot == _main_hand_slot or _hand_busy:
		return
	_hand_busy = true

	var anim_chain = AnimChain.new()

	var move_hand_to_slot = func ():
		_typed_rig.main_hand_ik.reach_to(target_slot.global_position, anim_chain.next)
	anim_chain.add(move_hand_to_slot)

	var finalize = func ():
		if _main_hand_slot.item != null:
			_main_hand_slot.item.update_attachment.rpc(target_slot.get_attachment_string())
		if target_slot.item != null:
			target_slot.item.update_attachment.rpc(_main_hand_slot.get_attachment_string())
		_hand_busy = false
	anim_chain.add(finalize)

	anim_chain.next.call()

func stow_main_hand_item():
	if _main_hand_slot.item == null or _hand_busy:
		return
	_hand_busy = true

	var clear = func ():
		_hand_busy = false

	var to_slot = inventory.get_available_slot_for(_main_hand_slot.item)
	_move_item_to_slot(_main_hand_slot.item, to_slot, clear)

func _chain_ensure_main_hand_clear(anim_chain: AnimChain):
	if _main_hand_slot.is_available():
		return

	var active_dest_slot = inventory.get_available_slot_for(_main_hand_slot.item)
	var free_hand = func ():
		_move_item_to_slot(_main_hand_slot.item, active_dest_slot, anim_chain.next)
	anim_chain.add(free_hand)

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
