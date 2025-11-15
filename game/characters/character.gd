class_name Character extends CharacterBody3D

@export var speed: float = 5.0

var collider: CollisionShape3D = null
var rig: Rig = null
var inventory: Inventory = null

@export var move_direction: Vector2 = Vector2.ZERO
@export var look_rotation: Vector3 = Vector3.FORWARD
@export var look_target: Vector3 = Vector3.ZERO

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
	rotate_y(look_rotation.y)
	update_velocity(delta)
	move_and_slide()

func update_velocity(delta):
	var current_speed = get_current_speed()
	if not move_direction.is_zero_approx():
		var planar_move = Vector3(move_direction.x, 0, move_direction.y)
		var direction = (transform.basis * planar_move).normalized()
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

func get_current_speed():
	return speed
