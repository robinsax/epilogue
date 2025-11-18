class_name Character extends CharacterBody3D

@export var speed: float = 3.5
@export var interact_reach: float = 1.5

var collider: CollisionShape3D = null
var rig: Rig = null
var inventory: Inventory = null

@export var move_direction: Vector3 = Vector3.ZERO
@export var aim_target: Vector3 = Vector3.ZERO
@export var look_target: Vector3 = Vector3.ZERO
@export var aiming: bool = false
@export var firing: bool = false
@export var dead: bool = false

var hitboxes: Array[CharacterHitbox] = []

static func find_parent_character(from: Node3D) -> Character:
	var current = from.get_parent()
	while current is not Character:
		current = current.get_parent()

	return current

func _ready():
	collider = $Collider
	rig = $Rig
	inventory = $Inventory

	var name_id = int(name)
	var authority = name_id
	# TODO: No.
	if name_id == 0 or (name_id > 1 and name_id < 1000):
		authority = 1
	set_multiplayer_authority(authority)
	if name_id == authority:
		var possession = load("res://meta/player_possession.tscn").instantiate()
		add_child(possession, true)

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
	move_and_slide()

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

func take_item(item: Item):
	var slot = inventory.get_available_slot_for(item)
	if not slot:
		return

	var attachment = inventory.get_attachment_string(slot)
	item.update_attachment.rpc(attachment)

func get_look_cast_ignore_rids() -> Array[RID]:
	return [self.get_rid()]

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
