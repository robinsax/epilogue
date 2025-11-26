@tool
class_name EnvironmentGenerationWorker extends Node

static var REQUEST_TYPE_TERRAIN = 1
static var REQUEST_TYPE_OBJECT_GENERATION = 2
static var REQUEST_TYPE_FOLIAGE = 3

class GenerationRequest:
	var type: int
	var call_id: int
	var params: Variant

class GenerationResult:
	var type: int
	var call_id: int
	var data: Variant

class WorkerInstance:
	var thread: Thread
	var active: bool

@export var worker_count: int = 2

var _workers: Array[WorkerInstance]
var _callbacks: Dictionary
var _queue: Array[GenerationRequest]
var _call_id: int

func _get_workers() -> Array[WorkerInstance]:
	if _workers.size() > 0:
		return _workers

	for i in worker_count:
		var instance = WorkerInstance.new()
		instance.thread = Thread.new()
		instance.active = false

		_workers.push_back(instance)

	return _workers

func _process(delta):
	for worker in _get_workers():
		if not worker.thread.is_alive() and worker.active:
			var result = worker.thread.wait_to_finish()
			worker.active = false

			_callbacks[result.call_id].call(result.data)
			_callbacks.erase(result.call_id)

			_maybe_dequeue()

func _exit_tree():
	for worker in _get_workers():
		if worker.thread.is_alive():
			worker.thread.wait_to_finish()

func _maybe_dequeue():
	for worker in _get_workers():
		if _queue.is_empty():
			return

		if worker.active:
			continue

		var next = null
		for item in _queue:
			if next == null or item.type < next.type:
				next = item

		_queue.remove_at(_queue.find(next))
		Stats.stats["envgen/q"] = _queue.size()
		worker.active = true
		worker.thread.start(_worker_compute.bind(next))

func _enqueue(type: int, params: Variant, callback: Callable):
	var request = GenerationRequest.new()
	request.type = type
	request.params = params
	_call_id += 1
	_callbacks[_call_id] = callback
	request.call_id = _call_id

	_queue.push_back(request)
	Stats.stats["envgen/q"] = _queue.size()
	_maybe_dequeue()

func _worker_compute(request: GenerationRequest) -> GenerationResult:
	var result = GenerationResult.new()
	result.type = request.type
	result.call_id = request.call_id

	if request.type == REQUEST_TYPE_FOLIAGE:
		result.data = compute_foliage_population(request.params)
	elif request.type == REQUEST_TYPE_OBJECT_GENERATION:
		result.data = run_object_generator(request.params)
	elif request.type == REQUEST_TYPE_TERRAIN:
		result.data = generate_terrain(request.params)

	return result

func _make_ground_sampler(
	height_sampler: NoiseSource.Sampler, terrain_scale: float
) -> QuadInterpolatedSampler:
	var instance = QuadInterpolatedSampler.new()
	instance.height_sampler = height_sampler
	instance.terrain_scale = terrain_scale

	return instance

class FoliagePopulationPass:
	var density_sampler: NoiseSource.Sampler
	var density_cutoff: Curve
	var samples: int

class FoliagePopulationParams:
	var gen_seed: int
	var global_position: Vector3
	var passes: Array[FoliagePopulationPass]
	var terrain_scale: float
	var terrain_subdivisions: int
	var terrain_global_position: Vector3
	var chunk_size: float
	var scale_min: float
	var scale_max: float
	var slope_limit: float
	var shader: ShaderMaterial
	var instance_mesh: Mesh
	var height_sampler: NoiseSource.Sampler
	var biomes_texture: Texture2D
	var paths_image: Image

func request_foliage_population(params: FoliagePopulationParams, callback: Callable):
	_enqueue(REQUEST_TYPE_FOLIAGE, params, callback)

func compute_foliage_population(params: FoliagePopulationParams) -> MultiMeshInstance3D:
	var rand = RandomNumberGenerator.new()
	rand.seed = params.gen_seed

	var ground_sampler = _make_ground_sampler(
		params.height_sampler, params.terrain_scale
	)

	var transforms: Array[Transform3D] = []
	for gen_pass in params.passes:
		var sample_size = params.chunk_size / float(gen_pass.samples)
		for x in gen_pass.samples:
			for z in gen_pass.samples:
				var point = (
					# Volume base position.
					params.global_position +
					# Sample offset.
					Vector3(x * sample_size, 0.0, z * sample_size) +
					# Randomized offset within sample.
					Vector3(rand.randf() * sample_size, 0.0, rand.randf() * sample_size)
				)

				var paths_coord = floor((point - params.terrain_global_position) / params.terrain_scale)
				var paths_pixel = params.paths_image.get_pixel(int(paths_coord.x), int(paths_coord.z))
				if paths_pixel.r > 0.0 or paths_pixel.g > 0.0 or paths_pixel.b > 0.0:
					continue

				var sample_point = Vector2(point.x, point.z)
				var density_sample = gen_pass.density_sampler.sample(sample_point)
				if rand.randf() > gen_pass.density_cutoff.sample(density_sample):
					continue

				var slope_sample = ground_sampler.sample_slope(sample_point)
				if slope_sample > params.slope_limit:
					continue

				point.y = ground_sampler.sample(sample_point) * params.terrain_scale

				var scale = params.scale_min + (rand.randf() * (params.scale_max - params.scale_min))
				var rotation = rand.randf() * PI * 2

				var transform = Transform3D(
					Basis(Vector3.UP, rotation).scaled(Vector3.ONE * scale),
					point - params.global_position
				)
				transforms.push_back(transform)

	var multimesh_node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = params.instance_mesh
	multimesh_node.multimesh = multimesh

	multimesh_node.material_override = params.shader

	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i]) 

	return multimesh_node

class EnvironmentObjectGenerationPass:
	var generator: EnvironmentObjectSource.Generator
	var placements: int

class EnvironmentObjectGenerationParams:
	var gen_seed: int
	var height_sampler: NoiseSource.Sampler
	var terrain_scale: float
	var terrain_subdivisions: int
	var global_position: Vector3
	var biome_samplers: Array[NoiseSource.Sampler]
	var passes: Array[EnvironmentObjectGenerationPass]
	var paths_image: Image

func request_object_generation(params: EnvironmentObjectGenerationParams, callback: Callable):
	_enqueue(REQUEST_TYPE_OBJECT_GENERATION, params, callback)

class Placement:
	var placement: Vector2
	var exclude_radius: float

func run_object_generator(params: EnvironmentObjectGenerationParams) -> Node3D:
	var terrain_size = params.terrain_subdivisions * params.terrain_scale
	var existing_placements: Array[Placement] = []

	var rand = RandomNumberGenerator.new()
	rand.seed = params.gen_seed

	var ground_sampler = _make_ground_sampler(
		params.height_sampler, params.terrain_scale
	)

	var gen_params = EnvironmentObjectSource.GeneratorParams.new()
	gen_params.biome_samplers = params.biome_samplers
	gen_params.ground_sampler = ground_sampler
	gen_params.height_sampler = params.height_sampler
	gen_params.rand = rand
	gen_params.terrain_scale = params.terrain_scale

	var root = Node3D.new()

	for gen_pass in params.passes:
		for i in gen_pass.placements:
			for k in 10:
				var point_offset = Vector2(
					rand.randf() * terrain_size,
					rand.randf() * terrain_size
				)
				var base_point = Vector2(
					params.global_position.x,
					params.global_position.z
				) + point_offset
				var overlap = false
				for check in existing_placements:
					if _fast_circle_contains(check.placement, check.exclude_radius, base_point):
						overlap = true
						break
				if overlap:
					continue

				var paths_coord = floor(point_offset / params.terrain_scale)
				var paths_pixel = params.paths_image.get_pixel(int(paths_coord.x), int(paths_coord.y))
				if paths_pixel.r > 0.0 or paths_pixel.g > 0.0 or paths_pixel.b > 0.0:
					continue

				var base_point_y = ground_sampler.sample(base_point) * params.terrain_scale
				var base_position = Vector3(base_point.x, base_point_y, base_point.y)

				gen_params.base_position = base_position

				var result = gen_pass.generator.generate(gen_params)
				root.add_child(result.node)
				result.node.position = base_position - params.global_position

				var pass_result = Placement.new()
				pass_result.exclude_radius = result.radius
				pass_result.placement = base_point
				existing_placements.push_back(pass_result)
				break

	return root

func _fast_circle_contains(center: Vector2, r: float, check: Vector2) -> bool:
	var dx = abs(check.x - center.x)
	var dy = abs(check.y - center.y)
	if dx + dy <= r:
		return true
	if dx > r:
		return false
	if dy > r:
		return false
	if pow(dx, 2) + pow(dy, 2) <= pow(r, 2):
		return true
	return false

class TerrainGenerationParams:
	var offset: Vector2
	var gen_seed: int
	var terrain_subdivisions: int
	var terrain_scale: float
	var height_sampler: NoiseSource.Sampler
	var biome_samplers: Array[NoiseSource.Sampler]
	var path_resolvers: Array[EnvironmentPathSource.Resolver]
	var shader: ShaderMaterial

class TerrainGenerationResult:
	var mesh: Mesh
	var collider: CollisionObject3D
	var biomes_image: Image
	var paths_image: Image

func request_terrain_generation(params: TerrainGenerationParams, callback: Callable):
	_enqueue(REQUEST_TYPE_TERRAIN, params, callback)

func generate_terrain(params: TerrainGenerationParams) -> TerrainGenerationResult:
	var mesh = _make_terrain_mesh(
		params.offset, params.terrain_scale, params.terrain_subdivisions, params.height_sampler
	)
	var mesh_node = MeshInstance3D.new()

	var rand = RandomNumberGenerator.new()
	rand.seed = params.gen_seed

	var heights_tex = ImageTexture.create_from_image(params.height_sampler.to_image(
		params.offset, params.terrain_scale, params.terrain_subdivisions
	))

	var biome_images: Array[Image] = []
	for sampler in params.biome_samplers:
		biome_images.push_back(sampler.to_image(
			params.offset - (Vector2(1.0, 1.0) * params.terrain_scale),
			params.terrain_scale,
			params.terrain_subdivisions + 2
		))

	var path_params = EnvironmentPathSource.ResolverParams.new()
	path_params.height_sampler = params.height_sampler
	path_params.terrain_subdivisions = params.terrain_subdivisions
	path_params.terrain_scale = params.terrain_scale
	path_params.offset = params.offset
	path_params.rand = rand

	var paths_image = Image.create_empty(
		params.terrain_subdivisions, params.terrain_subdivisions, false, Image.FORMAT_RGB8
	)
	for i in params.path_resolvers.size():
		params.path_resolvers[i].update_image(paths_image, i, path_params)

	for x in params.terrain_subdivisions:
		for z in params.terrain_subdivisions:
			var color = Color(
				biome_images[0].get_pixel(x, z).r,
				biome_images[1].get_pixel(x, z).r,
				biome_images[2].get_pixel(x, z).r
			)
			biome_images[0].set_pixel(x, z, color)

	var shader_inst = params.shader.duplicate()
	mesh.surface_set_material(0, shader_inst)
	shader_inst.set_shader_parameter("heights", heights_tex)
	shader_inst.set_shader_parameter("biomes", ImageTexture.create_from_image(biome_images[0]))
	shader_inst.set_shader_parameter("paths", ImageTexture.create_from_image(paths_image))

	mesh_node.mesh = mesh

	var collider = _create_heightmap_collider(
		params.terrain_subdivisions, params.terrain_scale, params.height_sampler,
		params.offset
	)

	var result = TerrainGenerationResult.new()
	result.biomes_image = biome_images[0]
	result.paths_image = paths_image
	result.mesh = mesh
	result.collider = collider

	return result

func _create_heightmap_collider(
	terrain_subdivisions: int, terrain_scale: float, height_sampler: NoiseSource.Sampler, offset: Vector2
) -> StaticBody3D:
	var static_body = StaticBody3D.new()
	
	var shape = HeightMapShape3D.new()
	var map_size = terrain_subdivisions + 1
	shape.map_width = map_size
	shape.map_depth = map_size
	
	var map_data = PackedFloat32Array()
	map_data.resize(map_size * map_size)
	
	for z in map_size:
		for x in map_size:
			var height = height_sampler.sample(offset + (Vector2(x, z) * terrain_scale))
			map_data[z * map_size + x] = height
	
	shape.map_data = map_data
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	collision_shape.scale = Vector3(terrain_scale, terrain_scale, terrain_scale)
	
	static_body.add_child(collision_shape)
	
	return static_body

func _make_terrain_mesh(
	offset: Vector2, terrain_scale: float, terrain_subdivisions: int, height_sampler: NoiseSource.Sampler
) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = []
	var uvs = []

	for z in range(terrain_subdivisions + 1):
		for x in range(terrain_subdivisions + 1):
			var height = height_sampler.sample(offset + (Vector2(x, z) * terrain_scale))

			var vertex = Vector3(x, height, z) * terrain_scale
			vertices.append(vertex)

			var uv = Vector2(
				float(x) / terrain_subdivisions,
				float(z) / terrain_subdivisions
			)
			uvs.append(uv)
	
	for z in range(terrain_subdivisions):
		for x in range(terrain_subdivisions):
			var i = z * (terrain_subdivisions + 1) + x
			
			var v1 = vertices[i]
			var v2 = vertices[i + 1]
			var v3 = vertices[i + terrain_subdivisions + 1]
			
			var uv1 = uvs[i]
			var uv2 = uvs[i + 1]
			var uv3 = uvs[i + terrain_subdivisions + 1]
			
			var normal1 = (v2 - v1).cross(v3 - v1).normalized()
			
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv1)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv2)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal1)
			surface_tool.set_uv(uv3)
			surface_tool.add_vertex(v3)
			
			var v4 = vertices[i + 1]
			var v5 = vertices[i + terrain_subdivisions + 2]
			var v6 = vertices[i + terrain_subdivisions + 1]
			
			var uv4 = uvs[i + 1]
			var uv5 = uvs[i + terrain_subdivisions + 2]
			var uv6 = uvs[i + terrain_subdivisions + 1]
			
			var normal2 = (v5 - v4).cross(v6 - v4).normalized()
			
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv4)
			surface_tool.add_vertex(v4)
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv5)
			surface_tool.add_vertex(v5)
			surface_tool.set_normal(normal2)
			surface_tool.set_uv(uv6)
			surface_tool.add_vertex(v6)
	
	surface_tool.generate_normals()
	return surface_tool.commit()
