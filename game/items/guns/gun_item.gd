class_name GunItem extends Item

@export var character_low_ready_anchor: String = ""
@export var character_aim_anchor: String = ""
@export var biped_aim_radius: float = 0.1
@export var biped_body_rotation: float = 0.2
@export var biped_dominant_shoulder_push: float = 0.3
@export var action_cycle_time: float = 0.5
@export var fire_rate: float = 0.3
@export var fire_recycle_time: float = 0.1
@export var vertical_recoil: float = 0.3
@export var horizontal_recoil: float = 0.1
@export var recoil_time: float = 0.4

var magazine_well: InventorySlot = null
var _grip: Node3D = null
var _offhand__grip: Node3D = null
var _muzzle: Node3D = null
var _aim_anchor: Node3D = null

@export var action_projectile_type: String = ""
var _action_cycler: Node3D = null
var _action_cycler_grip: Node3D = null
var _action_cycler_stop: Node3D = null
var _cycling_action: bool = false
var _action_cycling_time: float = 0.0
var _base_action_cycler_position: Vector3 = Vector3.ZERO

var _recoil_cooldown_time: float = 0.0
var _fire_cooldown_time: float = 0.0
var _recoil_seed: float = 0.0

var _current_vertical_recoil: float = 0.0
var _current_horizontal_recoil: float = 0.0

func _ready():
	super._ready()
	_grip = $Grip
	_offhand__grip = $OffhandGrip
	_muzzle = $Muzzle
	_aim_anchor = $AimAnchor
	_action_cycler = $ActionCycler
	_action_cycler_grip = $ActionCycler/ActionGrip
	_action_cycler_stop = $ActionCyclerStop
	if _action_cycler:
		_base_action_cycler_position = _action_cycler.position
	magazine_well = inventory.get_slot("magwell")

func _process(delta):
	if not is_animated:
		if action_projectile_type == "":
			_action_cycler.position = _action_cycler_stop.position
		else:
			_action_cycler.position = _base_action_cycler_position

	super._process(delta)

func animate_biped_as_active(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	is_animated = true

	if _recoil_cooldown_time > 0.0:
		_recoil_cooldown_time -= delta

		_current_vertical_recoil = vertical_recoil * (_recoil_cooldown_time / recoil_time)
		_current_horizontal_recoil = horizontal_recoil * (_recoil_cooldown_time / recoil_time)

	_animate_biped_base(character, rig, delta)
	_animate_biped_manipulation(character, rig, delta)

func _animate_biped_base(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	if not character.aiming:
		var low_anchor = character.find_child(character_low_ready_anchor, true, false)
		global_rotation = low_anchor.global_rotation
		global_position = low_anchor.global_position
		rig.main_hand_ik.root_global_position = _grip.global_position
		return

	# Compute aim:
	# 1. Apply part of the rotation as torso influence.
	var torso_aim_direction = (character.aim_target - rig.get_torso_position()).normalized()

	var horizontal_distance = Vector2(torso_aim_direction.z, torso_aim_direction.x).length()
	var pitch = atan2(torso_aim_direction.y, horizontal_distance)

	rig.torso_aim_influence = (
		Basis(Vector3.BACK, pitch) *
		Basis(Vector3.UP, -biped_dominant_shoulder_push - (_current_horizontal_recoil * 0.4))
	)

	# 2. Compute anchor point aligned with aim point based off the aim anchor.
	var aim_center_position =  character.find_child(character_aim_anchor, true, false).global_position
	var anchor_aim_direction = (character.aim_target - aim_center_position).normalized()

	var anchor_position = aim_center_position + (anchor_aim_direction * biped_aim_radius)

	# 3. Align gun.
	var own_aim_direction = (character.aim_target - global_position).normalized()
	var new_basis = Basis()
	new_basis.x = -own_aim_direction
	new_basis.z = new_basis.x.cross(Vector3.UP).normalized()
	new_basis.y = new_basis.z.cross(new_basis.x).normalized()

	var recoil_basis = (
		Basis(Vector3.FORWARD, _current_vertical_recoil) *
		Basis(Vector3.UP, ((_recoil_seed - 0.5) * PI) * _current_horizontal_recoil)
	)

	global_position = (
		anchor_position -
		(new_basis * _aim_anchor.position) -
		(Vector3.UP * _current_vertical_recoil * 0.1)
	)
	basis = new_basis * recoil_basis

	rig.off_hand_ik.root_global_position = _offhand__grip.global_position
	rig.main_hand_ik.root_global_position = _grip.global_position
	rig.head_aim_influence = Basis(Vector3.LEFT, -rig.head_aim_tilt)
	rig.basis = (
		Basis(Vector3.UP, -biped_body_rotation) *
		Basis(Vector3.LEFT, -_current_horizontal_recoil * 0.1)
	)

func _animate_biped_manipulation(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	if _fire_cooldown_time > 0.0:
		var recycle_thresh = fire_rate - fire_recycle_time
		var was_past_recycle_thresh = _fire_cooldown_time <= recycle_thresh
		_fire_cooldown_time -= delta

		if _fire_cooldown_time <= recycle_thresh:
			if not was_past_recycle_thresh:
				_chamber.rpc()
		else:
			var sin_value = sin(PI * (1.0 - ((_fire_cooldown_time - recycle_thresh) / recycle_thresh)))

			_action_cycler.position = (
				_base_action_cycler_position +
				(
					(_action_cycler_stop.position - _base_action_cycler_position) *
					sin_value
				)
			)

		return
	elif character.firing and action_projectile_type != "":
		_fire.rpc(randf())
		return

	if _cycling_action:
		_action_cycling_time += delta

		global_position = rig.front_position.global_position
		rig.main_hand_ik.root_global_position = _grip.global_position

		_action_cycler.position = (
			_base_action_cycler_position +
			(
				(_action_cycler_stop.position - _base_action_cycler_position) *
				sin(PI * (_action_cycling_time / action_cycle_time))
			)
		)

		if _action_cycling_time > action_cycle_time:
			_chamber.rpc()
			_cycling_action = false
			_action_cycling_time = 0.0
			rig.off_hand_ik.lock_to(null)
		return

	var can_cycle = (
		action_projectile_type == "" and _action_cycler != null and
		not rig.off_hand_ik.is_busy() and magazine_well.item != null and
		magazine_well.item.get_remaining_projectiles() > 0
	)
	if can_cycle:
		_cycling_action = true
		rig.off_hand_ik.lock_to(_action_cycler_grip)
		return

	if action_projectile_type == "":
		_action_cycler.position = _action_cycler_stop.position

func is_chambered():
	return action_projectile_type != ""

@rpc("any_peer", "call_local")
func _chamber():
	if not is_multiplayer_authority():
		return

	if magazine_well.item == null:
		return

	var next = magazine_well.item.pop_next_projectile_type()
	if next != null:
		action_projectile_type = next.resource_path

@rpc("any_peer", "call_local")
func _fire(recoil_seed: float):
	_recoil_cooldown_time = recoil_time
	_recoil_seed = recoil_seed
	_fire_cooldown_time = fire_rate
	if action_projectile_type == "":
		return

	World.current.spawn_projectile(load(action_projectile_type), _muzzle.global_position, global_rotation)

	if is_multiplayer_authority():
		action_projectile_type = ""

func reload_as_active(character: Character) -> bool:
	var available_mag_slot = character.inventory.get_slot_with_item_tag(
		magazine_well.required_tag, [magazine_well]
	)
	if available_mag_slot == null:
		return false

	character.move_item_slots(available_mag_slot, magazine_well)
	return true

func get_hold_position():
	return _grip.position
