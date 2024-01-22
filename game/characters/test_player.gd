extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _game = null
var inventory = null
var collider = null
var camera = null
var mesh = null
var _input_sync = null

var _is_ready = false

var possession = null # local authority only

@export var profile_id = ""

@export var conn_id := 0 :
	set(id):
		var changed = conn_id != id
		conn_id = id
		if not changed:
			return

		$input_sync.set_multiplayer_authority(id)
		if _is_ready:
			_maybe_possess()

func _ready():
	_game = get_node("/root/game")
	inventory = $inventory
	collider = $collider
	mesh = $collider/mesh
	camera = $camera
	_input_sync = $input_sync
	
	_is_ready = true
	if _game.level.is_home():
		_maybe_possess()

func is_authority():
	return $input_sync.get_multiplayer_authority() == multiplayer.get_unique_id()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if $input_sync.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var rotation = $input_sync.rotation
	rotate_y(rotation.y)
	camera.rotate_x(rotation.x)

	var move_dir = $input_sync.move_direction
	var direction = (transform.basis * Vector3(move_dir.x, 0, move_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _maybe_possess():
	_input_sync.update_enabled()

	if not is_authority():
		return
	if not _game.level.is_home() and multiplayer.is_server():
		return

	print("possessing ", name)
	possession = load("res://meta/possession.tscn").instantiate()
	possession.bind(self)
	add_child(possession)

func interact_with(target):
	target.interacted_by(self)

func data():
	var item_data = []
	for item in inventory.items():
		item_data.append(item.data())

	return { "items": item_data }
