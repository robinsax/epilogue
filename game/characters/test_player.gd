extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var player := 1 :
	set(id):
		player = id
		$input_sync.set_multiplayer_authority(id)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _is_local_authority():
	return $input_sync.get_multiplayer_authority() == multiplayer.get_unique_id()

func _ready():
	if not _is_local_authority():
		return

	print("local authority ready")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$camera.current = true

func _process(delta):
	pass

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if $input_sync.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
	$input_sync.jumping = false
	
	var rotation = $input_sync.rotation
	rotate_y(rotation.y)
	$camera.rotate_x(rotation.x)

	var move_dir = $input_sync.move_direction
	var direction = (transform.basis * Vector3(move_dir.x, 0, move_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
