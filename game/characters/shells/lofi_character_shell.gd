class_name LoFiCharacterShell extends StaticBody3D

var character: Character
var _grounded: bool
var _ground_hit: Dictionary

var hard_culled_position: Vector3

class Interface extends CharacterShellInterface:
	var _shell: LoFiCharacterShell

	func get_name() -> String:
		return _shell.name

	func get_floor_angle() -> float:
		if not _shell._grounded:
			return 0.0
		return _shell._ground_hit.normal.angle_to(Vector3.UP)

	func is_on_floor() -> bool:
		return _shell._grounded

	func get_collision_mask() -> int:
		return _shell.collision_mask

	func physics_update_move(velocity: Vector3, delta: float):
		if _shell.character.bound_to_ground and _shell._grounded:
			velocity.y = max(velocity.y, -1.0)

		var motion = velocity * delta
		var safe_motion = _get_safe_motion(motion)

		_shell.global_position += safe_motion
		if _shell.character.bound_to_ground:
			if "position" in _shell._ground_hit and velocity.y <= 0.0:
				_shell.global_position.y = _shell._ground_hit.position.y - _shell.character.feet_position.position.y

	func _get_safe_motion(motion: Vector3) -> Vector3:
		var space_state = _shell.get_world_3d().direct_space_state
		var params = PhysicsShapeQueryParameters3D.new()
		params.shape = _shell.character.collider.shape
		params.transform = _shell.global_transform
		params.motion = motion
		params.collision_mask = CollisionLayers.PHYSICAL | CollisionLayers.CHARACTERS

		var result = space_state.cast_motion(params)
		
		if result.size() > 0:
			var safe_fraction = result[0]
			return motion * safe_fraction
		return motion

func _ready():
	character = $Character

	character.remove_child(character.collider)
	add_child(character.collider)

func get_interface() -> CharacterShellInterface:
	var interface = Interface.new()
	interface._shell = self

	return interface

func _physics_process(delta):
	if character.update_culled:
		return

	var cast = PhysicsRayQueryParameters3D.create(
		character.global_position,
		character.global_position + (Vector3.DOWN * character.grounded_cast_length),
		CollisionLayers.FAST_GROUND
	)
	var space = get_world_3d().direct_space_state

	var result = space.intersect_ray(cast)
	if "normal" in result:
		_grounded = true
		_ground_hit = result
	else:
		_grounded = false
		_ground_hit = {}
