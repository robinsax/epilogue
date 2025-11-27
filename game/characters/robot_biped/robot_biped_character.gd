class_name RobotBipedCharacter extends GroundCharacter

@export var punch_energy_burn: float = 2.0

var _typed_rig: RobotBipedRig
var _main_hand_slot: InventorySlot
var _hit_recv_sounds: ClippedAudioPlayer
var _item_action_active: bool
var punch_time: float
var _punch_side: bool
var _augmentation_slots: Array[InventorySlot]

func _ready():
	super._ready()
	_typed_rig = rig
	_main_hand_slot = inventory.get_slot("rhand")
	_augmentation_slots = [
		inventory.get_slot("wrist")
	]
	_hit_recv_sounds = $HitRecvSounds

	charge_port = $Rig/Skeleton/B_Torso/ChargePort
	leg_cripple_hitboxes = [
		$Rig/Skeleton/B_LLeg1/LLegHitbox1,
		$Rig/Skeleton/B_RLeg1/RLegHitbox1
	]

	augmentation_slots = [
		$Rig/Skeleton/B_RArm1/RArmAug,
		$Rig/Skeleton/B_LArm1/LArmAug,
		$Rig/Skeleton/B_Head/HeadRailSlot,
		$Rig/Skeleton/B_LArm2/WristSlot
	]

	perception_volumes.push_back($RadarPerception)
	chat_node = $Chat

func _process(delta):
	super._process(delta)

	if dead:
		set_process(false)
		set_physics_process(false)

	_update_hands_state(delta)

func _update_hands_state(delta):
	if punch_time > 0:
		punch_time -= delta

	_typed_rig.main_hand_ik.root_global_position = Vector3.ZERO
	_typed_rig.off_hand_ik.root_global_position = Vector3.ZERO
	_typed_rig.head_aim_influence = Basis.IDENTITY
	_typed_rig.torso_aim_influence = Basis.IDENTITY
	rig.rotation = Vector3.ZERO

	var item_anim = (
		_main_hand_slot.item != null and not _typed_rig.main_hand_ik.is_busy() and
		_main_hand_slot.item.wants_animate_biped(self)
	)
	if item_anim:
		_main_hand_slot.item.animate_biped_as_active(self, _typed_rig, delta)
	elif punch_time > 0.0 or aiming:
		var offset = Vector3.ZERO
		if look_target.y - global_position.y < -0.4:
			offset.y -= 0.3
		_typed_rig.off_hand_ik.root_global_position = _typed_rig.fists_left_anchor.global_position + offset
		_typed_rig.main_hand_ik.root_global_position = _typed_rig.fists_right_anchor.global_position + offset

		var do_punch = aiming and firing and can_perform_actions()
		if do_punch:
			punch_time = 0.3
			_punch_side = not checking_status and randf() < 0.4

		if punch_time > 0.0:
			var punch_offset = (
				Vector3.FORWARD.rotated(Vector3.UP, global_rotation.y) * punch_time * 3.0
			)

			var hand_ik = _typed_rig.main_hand_ik
			if _punch_side:
				hand_ik = _typed_rig.off_hand_ik
			hand_ik.root_global_position += punch_offset
			if do_punch:
				World.current.spawn_projectile(
					load("res://projectiles/punch_projectile.tscn"),
					hand_ik.root_global_position, Vector3.ZERO, self
				)
				energy -= punch_energy_burn

	if checking_status and not _typed_rig.off_hand_ik.is_busy():
		_typed_rig.off_hand_ik.root_global_position = _typed_rig.status_check_anchor.global_position

func get_look_cast_ignore_rids() -> Array[RID]:
	var rids = super.get_look_cast_ignore_rids()

	if _main_hand_slot.item:
		rids.push_back(_main_hand_slot.item.get_rid())

	return rids

func get_hand_slot() -> InventorySlot:
	return _main_hand_slot

func can_perform_actions():
	return not _item_action_active and punch_time <= 0.0

func _pick_hand_ik_for_anim():
	if _main_hand_slot.is_available() and not _typed_rig.main_hand_ik.is_busy():
		return _typed_rig.main_hand_ik
	elif not _typed_rig.off_hand_ik.is_busy():
		# Offhand slot is a dummy for anims only, it's never available.
		return _typed_rig.off_hand_ik
	else:
		return null

func take_item(item: Item):
	if not can_perform_actions():
		return

	var slot = inventory.get_available_slot_for(item)
	if slot == null:
		return

	var anim_chain = AnimChain.new()
	var hand_ik = _pick_hand_ik_for_anim()
	if hand_ik == null:
		return

	_item_action_active = true

	var take_to_hand = func ():
		hand_ik.reach_to(item.global_position, anim_chain.next)
	anim_chain.add(take_to_hand)

	if hand_ik != _typed_rig.main_hand_ik or slot != _main_hand_slot:
		var move_to_slot = func ():
			item.update_attachment.rpc(hand_ik.slot.get_attachment_string())
			hand_ik.reach_to(slot.global_position, anim_chain.next)
		anim_chain.add(move_to_slot)

	var finalize = func ():
		item.update_attachment.rpc(slot.get_attachment_string())
		_item_action_active = false
		anim_chain.next.call()
	anim_chain.add(finalize)

	anim_chain.next.call()

func drop_item_slot(target_slot: InventorySlot):
	if not can_perform_actions():
		return

	var item = target_slot.item
	if item == null:
		return

	var anim_chain = AnimChain.new()
	var hand_ik = _pick_hand_ik_for_anim()
	if target_slot == _main_hand_slot and not _typed_rig.main_hand_ik.is_busy():
		hand_ik = _typed_rig.main_hand_ik

	if hand_ik == null:
		return

	_item_action_active = true

	if target_slot != _main_hand_slot:
		var take_to_hand = func ():
			hand_ik.reach_to(target_slot.global_position, anim_chain.next)
		anim_chain.add(take_to_hand)

	var move_to_front = func ():
		item.update_attachment.rpc(hand_ik.slot.get_attachment_string())
		hand_ik.reach_to(_typed_rig.front_position.global_position, anim_chain.next)
	anim_chain.add(move_to_front)

	var drop = func ():
		item.update_attachment.rpc("")
		_item_action_active = false
		anim_chain.next.call()
	anim_chain.add(drop)

	anim_chain.next.call()

func move_item_slots(from_slot: InventorySlot, to_slot: InventorySlot):
	if not can_perform_actions():
		return

	var item = from_slot.item
	var replaced_item = to_slot.item
	var replaced_item_dest_slot = inventory.get_available_slot_for(item)
	if item == null or not to_slot.is_item_compatible(item):
		return

	var anim_chain = AnimChain.new()
	var hand_ik = _pick_hand_ik_for_anim()
	if hand_ik == null:
		return

	_item_action_active = true

	if from_slot != hand_ik.slot:
		var move_hand_to_from = func ():
			hand_ik.reach_to(from_slot.global_position, anim_chain.next)
		anim_chain.add(move_hand_to_from)

	if to_slot != hand_ik.slot:
		var move_hand_to_to = func ():
			item.update_attachment.rpc(hand_ik.slot.get_attachment_string())
			hand_ik.reach_to(to_slot.global_position, anim_chain.next)
		anim_chain.add(move_hand_to_to)

	var finalize_target = func ():
		item.update_attachment.rpc(to_slot.get_attachment_string())
		if replaced_item != null:
			replaced_item.update_attachment.rpc(hand_ik.slot.get_attachment_string())
		anim_chain.next.call()
	anim_chain.add(finalize_target)

	if replaced_item != null and replaced_item_dest_slot != hand_ik.slot:
		var move_hand_to_replace_dest = func ():
			var dest_position = _typed_rig.front_position.global_position
			if replaced_item_dest_slot != null:
				dest_position = replaced_item_dest_slot.global_position
			hand_ik.reach_to(dest_position, anim_chain.next)
		anim_chain.add(move_hand_to_replace_dest)

		var finalize_replace = func ():
			if replaced_item_dest_slot != null:
				replaced_item.update_attachment.rpc(replaced_item_dest_slot.get_attachment_string())
			else:
				replaced_item.update_attachment.rpc("")
			anim_chain.next.call()
		anim_chain.add(finalize_replace)

	var finalize = func ():
		_item_action_active = false
		anim_chain.next.call()
	anim_chain.add(finalize)

	anim_chain.next.call()

func manage_item_slot(target_slot: InventorySlot):
	if not can_perform_actions():
		return

	# Take item to main hand slot.
	if target_slot == _main_hand_slot or _typed_rig.main_hand_ik.is_busy():
		return

	var main_hand_item_cant_put = (
		_main_hand_slot.item != null and
		not target_slot.is_item_compatible(_main_hand_slot.item)
	)
	if target_slot.is_available() and main_hand_item_cant_put:
		return

	var anim_chain = AnimChain.new()

	_item_action_active = true

	if main_hand_item_cant_put:
		var active_dest_slot = inventory.get_available_slot_for(_main_hand_slot.item)
		var move_hand_to_active_dest = func ():
			var dest_position = _typed_rig.front_position.global_position
			if active_dest_slot != null:
				dest_position = active_dest_slot.global_position

			_typed_rig.main_hand_ik.reach_to(dest_position, anim_chain.next)
		anim_chain.add(move_hand_to_active_dest)

		var finalize_free = func ():
			if active_dest_slot != null:
				_main_hand_slot.item.update_attachment.rpc(active_dest_slot.get_attachment_string())
			else:
				_main_hand_slot.item.update_attachment.rpc("")
			anim_chain.next.call()
		anim_chain.add(finalize_free)

	var move_hand_to_slot = func ():
		_typed_rig.main_hand_ik.reach_to(target_slot.global_position, anim_chain.next)
	anim_chain.add(move_hand_to_slot)

	var finalize = func ():
		if _main_hand_slot.item != null:
			_main_hand_slot.item.update_attachment.rpc(target_slot.get_attachment_string())
		if target_slot.item != null:
			target_slot.item.update_attachment.rpc(_main_hand_slot.get_attachment_string())
		_item_action_active = false
		anim_chain.next.call()
	anim_chain.add(finalize)

	anim_chain.next.call()

func reload_active_item():
	if not can_perform_actions():
		return

	var active_item = _main_hand_slot.item
	if active_item == null:
		return

	active_item.reload_as_active(self)

func stow_active_item():
	if not can_perform_actions():
		return

	if _main_hand_slot.item == null or _typed_rig.main_hand_ik.is_busy():
		return

	var anim_chain = AnimChain.new()
	var dest_slot = inventory.get_available_slot_for(_main_hand_slot.item)

	var move_to_dest = func ():
		var dest_position = _typed_rig.front_position.global_position
		if dest_slot != null:
			dest_position = dest_slot.global_position
		_typed_rig.main_hand_ik.reach_to(dest_position, anim_chain.next)
	anim_chain.add(move_to_dest)

	var finalize = func ():
		if dest_slot != null:
			_main_hand_slot.item.update_attachment.rpc(dest_slot.get_attachment_string())
		else:
			_main_hand_slot.item.update_attachment.rpc("")
		anim_chain.next.call()
	anim_chain.add(finalize)

	anim_chain.next.call()

func do_hit_cosmetics(from: Projectile):
	_hit_recv_sounds.play_random_clip(0, 2)
