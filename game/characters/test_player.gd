extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var inventory = null

var active_interact_target = null # client only

@export var player := 1 :
	set(id):
		player = id
		$input_sync.set_multiplayer_authority(id)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _is_local_authority():
	return $input_sync.get_multiplayer_authority() == multiplayer.get_unique_id()

func _ready():
	inventory = $inventory

	if not _is_local_authority():
		return

	print("local authority ready")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$camera.current = true
	$collider/mesh.set_layer_mask_value(2, true)
	

func _process(delta):
	if not _is_local_authority():
		return
		
	if Input.is_action_pressed("inventory"):
		$ui/inventory.show()
	else:
		$ui/inventory.hide()

	var target_hud_ui = $ui/hud/active_interact_target

	if active_interact_target != null:
		target_hud_ui.text = active_interact_target.get_character_interact_info()

		if $input_sync.interacting:
			active_interact_target.character_interact(self)
	else:
		target_hud_ui.text = ""
		
	# todo move to own scene
	$ui/inventory/player_view_container/player_view/camera.position = global_position - Vector3(0.0, 0.0, 2.0)
	$ui/inventory/player_view_container/player_view/lamp.position = global_position - Vector3(0.0, 0.0, 2.0)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if $input_sync.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
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
	_handle_look(delta)

func _handle_look(delta):
	if not _is_local_authority():
		return
		
	active_interact_target = null

	var space = get_world_3d().direct_space_state
	var viewport = get_viewport()
	var viewport_center = viewport.size / 2.0

	var ray_origin = $camera.project_ray_origin(viewport_center)
	var ray_end = ray_origin + $camera.project_ray_normal(viewport_center) * 100.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)

	var result = space.intersect_ray(query)
	if "collider" not in result:
		return

	var collider = result["collider"]
	if collider.has_method("character_interact"):
		active_interact_target = collider
