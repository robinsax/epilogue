class_name LoFiCharacterShell extends StaticBody3D

var character: Character = null
var _grounded: bool = false
var _ground_hit: Dictionary = {}

class Interface extends CharacterShellInterface:
	var _shell: LoFiCharacterShell = null

	func get_floor_angle() -> float:
		if not _shell._grounded:
			return 0.0
		return _shell._ground_hit.normal.angle_to(Vector3.UP)

	func is_on_floor() -> bool:
		return _shell._grounded

	func get_collision_mask() -> int:
		return _shell.collision_mask

	func physics_update_move(velocity: Vector3, delta: float):
		if _shell._grounded:
			velocity.y = max(velocity.y, -1.0)

		# Manual collision check using shape cast or ray
		var motion = velocity * delta
		var safe_motion = _get_safe_motion(motion)

		_shell.global_position += safe_motion
		if "position" in _shell._ground_hit and velocity.y <= 0.0:
			_shell.global_position.y = _shell._ground_hit.position.y - _shell.character.feet_position.position.y

	func _get_safe_motion(motion: Vector3) -> Vector3:
		# Use PhysicsDirectSpaceState3D for queries
		var space_state = _shell.get_world_3d().direct_space_state
		var params = PhysicsShapeQueryParameters3D.new()
		params.shape = _shell.character.collider.shape
		params.transform = _shell.global_transform
		params.motion = motion
		params.collision_mask = CollisionLayerValues.PHYSICAL

		var result = space_state.cast_motion(params)
		
		if result.size() > 0:
			var safe_fraction = result[0]
			return motion * safe_fraction
		return motion

func _ready():
	character = $Character

	character.remove_child(character.collider)
	add_child(character.collider)

	_possess_if_owned()

# TODO: No - copied.
func _possess_if_owned():
	var name_id = int(name)
	var authority = name_id
	# TODO: No.
	if name_id == 0 or (name_id > 1 and name_id < 1000):
		authority = 1
	set_multiplayer_authority(authority)
	if name_id == authority:
		var possession = load("res://meta/player_possession.tscn").instantiate()
		character.add_child(possession, true)

func get_interface() -> CharacterShellInterface:
	var interface = Interface.new()
	interface._shell = self

	return interface

func _physics_process(delta):
	var cast = PhysicsRayQueryParameters3D.create(
		character.global_position,
		character.global_position + (Vector3.DOWN * 1.0),
		CollisionLayerValues.FAST_GROUND
	)
	var space = get_world_3d().direct_space_state

	var result = space.intersect_ray(cast)
	if "normal" in result:
		_grounded = true
		_ground_hit = result
	else:
		_grounded = false
		_ground_hit = {}
