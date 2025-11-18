class_name GrassVolume extends Area3D

@export var radius: float = 10.0
@export var mesh_downward_offset: float = 1.0

func _ready():
	call_deferred("_generate")

func _generate():
	var _mesh_instance: MultiMeshInstance3D = $MultiMesh
	var _mesh = _mesh_instance.multimesh
	_mesh.instance_count = 1000

	for i in _mesh.instance_count:
		var point = global_position + Vector3((0.5 - randf()) * 2.0 * radius, 0.0, (0.5 - randf()) * radius)
		var pos = _get_ground_position(point)
		_mesh.set_instance_transform(i, Transform3D(Basis(), pos - global_position))

func _get_ground_position(for_point: Vector3) -> Vector3:
	var query = PhysicsRayQueryParameters3D.create(
		for_point + (Vector3.UP * radius),
		for_point + (Vector3.DOWN * radius)
	)
	query.collision_mask = CollisionLayerValues.PHYSICAL

	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(query)
	if "position" in result:
		return result.position

	return Vector3.ZERO
