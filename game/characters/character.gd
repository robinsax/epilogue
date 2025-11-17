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

func _ready():
	collider = $Collider
	rig = $Rig
	inventory = $Inventory

	print(name, " ready")
	set_multiplayer_authority(int(name))
	if is_multiplayer_authority():
		print("...as authority")
		var possession = load("res://meta/player_possession.tscn").instantiate()
		add_child(possession, true)

func _process(_delta):
	pass

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

func drop_item_slot(target_slot: InventorySlot):
	if target_slot.item == null:
		return

	target_slot.item.update_attachment.rpc("")
