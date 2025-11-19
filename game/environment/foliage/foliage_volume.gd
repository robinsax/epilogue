@tool
class_name FoliageVolume extends Area3D

@export_tool_button("Generate", "Callable") var generate_action = generate

@export var instance_mesh: Mesh = null
@export var clump_noise: Noise = null
@export var placement_samples: int = 100
@export var cutoff: float = 0.0

var _biomes: Texture2D = null
var _terrain_size: int = 0
var _terrain_offset: Vector3 = Vector3.ZERO

func configure(biomes: Texture2D, terrain_offset: Vector3, terrain_size: int):
	_biomes = biomes
	_terrain_offset = terrain_offset
	_terrain_size = terrain_size

func generate():
	var shape: BoxShape3D = $Shape.shape
	var mesh_instance: MultiMeshInstance3D = $MultiMesh
	var mesh = MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.mesh = instance_mesh
	mesh_instance.multimesh = mesh

	var size = shape.size.x
	var base_offset = Vector3(-size * 0.5, 0.0, -size * 0.5)
	var sample_size = size / float(placement_samples)
	var transforms: Array[Transform3D] = []
	for x in placement_samples:
		for z in placement_samples:
			var point = global_position + base_offset + Vector3(x * sample_size, 0.0, z * sample_size)
			var noise_sample = clump_noise.get_noise_2d(point.x, point.z)
			if noise_sample < cutoff:
				continue

			var ground_position = _get_ground_position(shape, point)

			var inst_scale = randf()
			var offset = Vector3(
				randf(), 0.0, randf()
			)

			var inst_transform = Transform3D(
				Basis(Vector3.UP, randf() * PI).scaled(Vector3.ONE * inst_scale),
				ground_position - global_position + offset
			)

			transforms.push_back(inst_transform)

	mesh.instance_count = transforms.size()
	for i in transforms.size():
		mesh.set_instance_transform(i, transforms[i]) 

	var mesh_shader = mesh.mesh.surface_get_material(0)
	mesh_shader.set_shader_parameter("biomes", _biomes)
	mesh_shader.set_shader_parameter("terrain_size", _terrain_size)
	mesh_shader.set_shader_parameter("terrain_offset", _terrain_offset)

func _get_ground_position(shape: BoxShape3D, for_point: Vector3) -> Vector3:
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(for_point.x, global_position.y + (shape.size.y / 2), for_point.z),
		Vector3(for_point.x, global_position.y - (shape.size.y / 2), for_point.z)
	)
	query.collision_mask = CollisionLayerValues.PHYSICAL

	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(query)
	if "position" in result:
		return result.position

	return Vector3.ZERO
