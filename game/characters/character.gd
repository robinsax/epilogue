class_name Character extends Node3D

@export var speed: float = 3.5
@export var interact_reach: float = 1.5

var collider: CollisionShape3D = null
var rig: Rig = null
var inventory: Inventory = null
var nav_agent: NavigationAgent3D = null
var shell: CharacterShellInterface = null

@export var move_direction: Vector3 = Vector3.ZERO
@export var aim_target: Vector3 = Vector3.ZERO
@export var look_target: Vector3 = Vector3.ZERO
@export var aiming: bool = false
@export var firing: bool = false
@export var dead: bool = false

var hitboxes: Array[CharacterHitbox] = []
var perception_volumes: Array[PerceptionVolume] = []
var feet_position: Node3D = null
var velocity: Vector3 = Vector3.ZERO

static func find_parent_character(from: Node3D) -> Character:
	var current = from.get_parent()
	while current is not Character:
		current = current.get_parent()

	return current

func _ready():
	collider = $Collider
	rig = $Rig
	inventory = $Inventory
	nav_agent = $NavAgent
	feet_position = $FeetPosition
	shell = get_parent().get_interface()

	perception_volumes = rig.get_perception_volumes()

func _process(_delta):
	_check_death()

func _check_death():
	# TODO: Awk this isn't server.
	if not is_multiplayer_authority():
		return

	for hitbox in hitboxes:
		if hitbox.current_hitpoints <= 0 and hitbox.is_cripple_lethal:
			dead = true
			set_process(false)
			set_physics_process(false)
			break

func _physics_process(delta):
	update_velocity(delta)
	shell.physics_update_move(velocity, delta)

func update_velocity(delta):
	var current_speed = get_current_speed()
	if not move_direction.is_zero_approx():
		var direction = (transform.basis * move_direction).normalized()
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

func get_current_speed():
	return speed

func get_hand_slot() -> InventorySlot:
	return null

func can_perform_actions():
	return true

func take_item(item: Item):
	var slot = inventory.get_available_slot_for(item)
	if slot == null:
		return

	var attachment = inventory.get_attachment_string(slot)
	item.update_attachment.rpc(attachment)

func get_perception_volumes_contents() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	for volume in perception_volumes:
		for node in volume.get_perception():
			if node == self or nodes.has(node):
				continue

			nodes.push_back(node)

	return nodes

func get_look_cast_ignore_rids() -> Array[RID]:
	return shell.get_rids()

func manage_item_slot(target_slot: InventorySlot):
	pass

func move_item_slots(from_slot: InventorySlot, to_slot: InventorySlot):
	pass

func reload_active_item():
	pass

func stow_active_item():
	pass

func drop_item_slot(target_slot: InventorySlot):
	if target_slot.item == null:
		return

	target_slot.item.update_attachment.rpc("")

func distribute_overflow_kinetic_damage(amount: float):
	var can_take: Array[CharacterHitbox] = []
	for hitbox in hitboxes:
		if hitbox.current_hitpoints > 0:
			can_take.push_back(hitbox)

	if can_take.size() == 0:
		return

	var per_box = amount / can_take.size()
	for hitbox in can_take:
		hitbox.take_kinetic_damage(per_box)
