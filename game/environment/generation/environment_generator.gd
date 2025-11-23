@tool
class_name EnvironmentGenerator extends Node3D

@export var world_chunks: int = 4
@export var terrain_subdivisions: int = 1000
@export var terrain_scale: float = 1.0
@export var terrain_shader: ShaderMaterial = null

@export_tool_button("Generate") var generate_action = _generate_action
@export_tool_button("Reset") var reset_action = _reset

signal root_terrain_ready()

var _volumes: Array[EnvironmentVolume] = []
var _worker: EnvironmentGenerationWorker = null
var _gen_seed: int = 0
var _height_sampler: NoiseSourceSampler = null
var _biome_samplers: Array[NoiseSourceSampler] = []
var _foliage_sources: Array[FoliageSource] = []
var _path_sources: Array[EnvironmentPathSource] = []
var _object_sources: Array[EnvironmentObjectSource] = []

var _cull_check_time: float = 0.0

func _ready():
	if not Engine.is_editor_hint():
		_generate_action()
		var env: WorldEnvironment = get_node_or_null("Env")
		env.environment.fog_enabled = true

func _process(delta):
	if _cull_check_time > 0.0:
		_cull_check_time -= delta
	else:
		_cull_check()
		_cull_check_time = 1.0

func _cull_check():
	var observer = Vector3.ZERO
	if Engine.is_editor_hint():
		observer = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position
	else:
		var camera = get_viewport().get_camera_3d()
		if camera:
			observer = camera.global_position

	observer.y = 0.0
	for volume in _volumes:
		if volume == null:
			# Editor doing weird shit.
			continue

		var volume_position = volume.global_position
		volume_position.y = 0.0
		var distance = observer.distance_to(volume_position)
		volume.update_volume_state(distance)

func _generate_action():
	generate(int(randf() * 1000))

func _reset():
	var terrain_root = get_node("Terrain")
	for child in terrain_root.get_children():
		terrain_root.remove_child(child)

	var foliage_root = get_node("Foliage")
	for child in foliage_root.get_children():
		foliage_root.remove_child(child)

func _init_refs():
	_volumes = []
	var terrain_root = get_node("Terrain")
	for node in terrain_root.get_children():
		if node is TerrainVolume:
			_volumes.push_back(node)
	var foliage_root = get_node("Foliage")
	for node in foliage_root.get_children():
		if node is FoliageVolume:
			_volumes.push_back(node)

	var heights: NoiseSource = get_node("NoiseSources/Heights")
	heights.before_sampling(_gen_seed)
	_height_sampler = heights.sampler()

	var raw_foliage_sources = get_node("FoliageSources").get_children()
	_foliage_sources = []
	for source in raw_foliage_sources:
		if source is FoliageSource:
			_foliage_sources.push_back(source)

			for gen_pass in source.get_passes():
				gen_pass.density_noise.before_sampling(_gen_seed)

	var raw_path_sources = get_node("PathSources").get_children()
	_path_sources = []
	for source in raw_path_sources:
		if source is EnvironmentPathSource:
			source.noise.before_sampling(_gen_seed)

			_path_sources.push_back(source)

	var raw_object_sources = get_node("ObjectSources").get_children()
	_object_sources = []
	for source in raw_object_sources:
		if source is EnvironmentObjectSource:
			_object_sources.push_back(source)

	_biome_samplers = [
		_init_biome_channel_sampler("NoiseSources/BiomeA"),
		_init_biome_channel_sampler("NoiseSources/BiomeB"),
		_init_biome_channel_sampler("NoiseSources/BiomeC")
	]

	_worker = get_node("Worker")

func _init_biome_channel_sampler(path: String) -> NoiseSourceSampler:
	var source = get_node_or_null(path)
	if source == null:
		source = NoiseSource.new()

	source.before_sampling(_gen_seed)
	return source.sampler()

func generate(gen_seed: int):
	_gen_seed = gen_seed
	_reset()
	_init_refs()

	var volume_scene = load("res://environment/generation/terrain_volume.tscn")
	var terrain_root = get_node("Terrain")
	var terrain_size = terrain_scale * terrain_subdivisions

	var rand = RandomNumberGenerator.new()
	rand.seed = gen_seed

	for x in world_chunks:
		for z in world_chunks:
			var terrain_volume = volume_scene.instantiate()
			# TODO: AAAAAAAAAAA No
			if x == 0 and z == 0:
				terrain_volume.is_root = true

			terrain_volume.init_volume(
				self,
				Vector3(terrain_size, 100.0, terrain_size), rand.randi_range(0, 1000),
				terrain_size * 2
			)

			_volumes.push_back(terrain_volume)

			terrain_root.add_child(terrain_volume)
			terrain_volume.owner = get_tree().edited_scene_root

			terrain_volume.position = Vector3(terrain_size * x, 0.0, terrain_size * z)

func populate_terrain(instance: TerrainVolume):
	var on_ready = func (result: EnvironmentGenerationWorker.TerrainGenerationResult):
		var biomes_texture = ImageTexture.create_from_image(result.biomes_image)
		instance.set_terrain(
			result.mesh, result.fast_collider, result.slow_collider, biomes_texture, result.paths_image
		)

		_generate_objects(instance)

		for foliage_source in _foliage_sources:
			_generate_foliage_source(instance, foliage_source)

		if instance.is_root:
			root_terrain_ready.emit()

	var params = EnvironmentGenerationWorker.TerrainGenerationParams.new()
	params.offset = Vector2(instance.position.x, instance.position.z)
	params.shader = terrain_shader
	params.terrain_scale = terrain_scale
	params.gen_seed = instance.gen_seed
	params.terrain_subdivisions = terrain_subdivisions
	params.height_sampler = _height_sampler
	params.biome_samplers = _biome_samplers
	params.path_resolvers = [] as Array[EnvironmentPathSource.Resolver]
	for source in _path_sources:
		params.path_resolvers.push_back(source.resolver())

	_worker.request_terrain_generation(params, on_ready)

func _generate_foliage_source(parent_terrain: TerrainVolume, source: FoliageSource):
	var foliage_root = get_node("Foliage")
	var terrain_size = terrain_subdivisions * terrain_scale
	var size = terrain_size / source.chunk_count

	var volume_scene = load("res://environment/foliage/foliage_volume.tscn")

	for x in source.chunk_count:
		for z in source.chunk_count:
			var volume_position = parent_terrain.position + Vector3(x * size, 0.0, z * size)

			var instance: FoliageVolume = volume_scene.instantiate()
			instance.init_volume(self, Vector3(size, 100.0, size), parent_terrain.gen_seed, source.cull_distance)
			instance.source = source
			instance.parent_terrain = parent_terrain

			foliage_root.add_child(instance)
			instance.owner = get_tree().edited_scene_root

			instance.position = volume_position

			_volumes.push_back(instance)

func _generate_objects(parent_terrain: TerrainVolume):
	var passes: Array[EnvironmentGenerationWorker.EnvironmentObjectGenerationPass] = []
	for source in _object_sources:
		var instance = EnvironmentGenerationWorker.EnvironmentObjectGenerationPass.new()
		instance.generator = source.generator()
		instance.placements = source.placements

		passes.push_back(instance)

	var params = EnvironmentGenerationWorker.EnvironmentObjectGenerationParams.new()
	params.passes = passes
	params.height_sampler = _height_sampler
	params.biome_samplers = _biome_samplers
	params.terrain_scale = terrain_scale
	params.terrain_subdivisions = terrain_subdivisions
	params.gen_seed = parent_terrain.gen_seed
	params.global_position = parent_terrain.global_position
	params.paths_image = parent_terrain.paths_image

	var on_ready = func (node: Node3D):
		parent_terrain.add_objects(node)

	_worker.request_object_generation(params, on_ready)

func populate_foliage(instance: FoliageVolume):
	var pass_nodes = instance.source.get_passes()
	var passes: Array[EnvironmentGenerationWorker.FoliagePopulationPass] = []
	for pass_node in pass_nodes:
		var worker_pass = EnvironmentGenerationWorker.FoliagePopulationPass.new()
		worker_pass.density_sampler = pass_node.density_noise.sampler()
		worker_pass.density_cutoff = pass_node.density_cutoff
		worker_pass.samples = pass_node.placement_samples

		passes.push_back(worker_pass)

	var terrain_size = terrain_scale * terrain_subdivisions

	var params = EnvironmentGenerationWorker.FoliagePopulationParams.new()
	params.passes = passes
	params.gen_seed = instance.gen_seed
	params.height_sampler = _height_sampler
	params.global_position = instance.position
	params.terrain_scale = terrain_scale
	params.terrain_subdivisions = terrain_subdivisions
	params.volume_size = terrain_size / instance.source.chunk_count
	params.scale_max = instance.source.scale_max
	params.scale_min = instance.source.scale_min
	params.slope_limit = instance.source.slope_limit
	params.paths_image = instance.parent_terrain.paths_image
	params.terrain_global_position = instance.parent_terrain.global_position

	var on_ready = func (transforms: Array[Transform3D]):
		instance.apply_population(
			transforms, instance.parent_terrain.biomes_texture, instance.parent_terrain.position, terrain_size
		)

	_worker.request_foliage_population_transforms(params, on_ready)
