@tool
class_name EnvironmentGenerator extends Node3D

static var FOLIAGE_IMPACTORS = 24

@export var terrain_chunk_count: int = 4
@export var foliage_chunk_count: int = 10
@export var terrain_subdivisions: int = 500
@export var terrain_scale: float = 1.0
@export var terrain_shader: ShaderMaterial = null
@export var global_room_tone: AudioStream = null

@export var terrain_generate_distance: float = 200.0
@export var foliage_generate_distance: float = 60.0
@export var terrain_cull_distance: float = 200.0
@export var objects_cull_distance: float = 100.0
@export var foliage_cull_distance: float = 40.0

@export_tool_button("Generate") var generate_action = _generate_action
@export_tool_button("Print Stats") var print_stats_action = _print_stats_action

signal root_terrain_ready()

var _worker: EnvironmentGenerationWorker
var _gen_seed: int
var _terrain_root: Node3D
var _height_sampler: NoiseSource.Sampler
var _biome_samplers: Array[NoiseSource.Sampler]
var _foliage_sources: Array[FoliageSource]
var _path_sources: Array[EnvironmentPathSource]
var _object_sources: Array[EnvironmentObjectSource]
var _observer_position: Vector3
var _foliage_impactor_cast: ShapeCast3D

var _cull_check_time: float
var _packed_impactors: Texture2D

func _generate_action():
	generate(int(randf() * 1000))

func _print_stats_action():
	var stats_str = ""
	for key in Stats.stats:
		stats_str += key + ": " + str(Stats.stats[key]) + "\n"

	print(stats_str)

func _ready():
	_terrain_root = $Terrain
	_worker = $Worker
	_foliage_impactor_cast = $FoliageImpactorCast

	for chunk in _terrain_root.get_children():
		chunk.generator = self

	if not Engine.is_editor_hint():
		_generate_action()
		var env: WorldEnvironment = get_node_or_null("Env")
		env.environment.fog_enabled = true

func _process(delta):
	if _packed_impactors != null:
		RenderingServer.global_shader_parameter_set("world_foliage_impactors", _packed_impactors)

	if _cull_check_time > 0.0:
		_cull_check_time -= delta
	else:
		_cull_check()
		_cull_check_time = 1.0

func _physics_process(delta: float) -> void:
	_update_foliage_impactors()

func _update_foliage_impactors():
	_foliage_impactor_cast.global_position = _observer_position

	Stats.stats["f/impacts"] = _foliage_impactor_cast.get_collision_count()

	var packing_image = Image.create_empty(FOLIAGE_IMPACTORS, 1, false, Image.FORMAT_RGBF)
	for i in _foliage_impactor_cast.get_collision_count():
		var impactor_position = _foliage_impactor_cast.get_collision_point(i)
		packing_image.set_pixel(i, 0, Color(impactor_position.x, impactor_position.y, impactor_position.z))

	_packed_impactors = ImageTexture.create_from_image(packing_image)

func _cull_check():
	_observer_position = Vector3.ZERO
	if Engine.is_editor_hint():
		_observer_position = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position
	else:
		var camera = get_viewport().get_camera_3d()
		if camera:
			_observer_position = camera.global_position
	Stats.stats["worldobs/pos"] = _observer_position
	var observer_position = _observer_position
	observer_position.y = 0.0

	var chunks = _terrain_root.get_children()
	Stats.stats["c/all"] = chunks.size()
	Stats.stats["o/active"] = 0
	Stats.stats["o/culled"] = 0
	Stats.stats["f/active"] = 0
	Stats.stats["f/culled"] = 0
	Stats.stats["t/active"] = 0
	Stats.stats["t/culled"] = 0
	Stats.stats["so/reg"] = 0
	for chunk in chunks:
		if chunk == null:
			# Editor doing weird shit.
			continue

		chunk.update_cull_state(observer_position)

func _init_sources():
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

func _init_biome_channel_sampler(path: String) -> NoiseSource.Sampler:
	var source = get_node_or_null(path)
	if source == null:
		source = NoiseSource.new()

	source.before_sampling(_gen_seed)
	return source.sampler()

func generate(gen_seed: int):
	_gen_seed = gen_seed

	Stats.stats["f/pop"] = 0

	for child in _terrain_root.get_children():
		_terrain_root.remove_child(child)
	_init_sources()

	var chunk_scene = load("res://environment/generation/terrain_chunk.tscn")
	var terrain_size = terrain_scale * terrain_subdivisions

	var rand = RandomNumberGenerator.new()
	rand.seed = gen_seed

	for x in terrain_chunk_count:
		for z in terrain_chunk_count:
			var chunk = chunk_scene.instantiate()
			# TODO: AAAAAAAAAAA No
			if x == 0 and z == 0:
				chunk.is_root = true

			chunk.generator = self
			chunk.gen_seed = rand.randi()
			chunk.rand = RandomNumberGenerator.new()
			chunk.rand.seed = chunk.gen_seed

			_terrain_root.add_child(chunk)
			chunk.owner = get_tree().edited_scene_root

			chunk.position = Vector3(terrain_size * x, 0.0, terrain_size * z)

func _generate_foliage_chunks(parent_terrain: TerrainChunk, gen_seed: int):
	var terrain_size = terrain_subdivisions * terrain_scale
	var chunk_scene = load("res://environment/generation/foliage_chunk.tscn")

	for x in foliage_chunk_count:
		for z in foliage_chunk_count:
			var size = terrain_size / foliage_chunk_count
			var chunk_position = Vector3(x * size, 0.0, z * size)

			var instance: FoliageChunk = chunk_scene.instantiate()
			instance.parent_terrain = parent_terrain
			instance.gen_seed = gen_seed

			parent_terrain.add_foliage(instance)
			instance.position = chunk_position

func populate_terrain(instance: TerrainChunk):
	var on_ready = func (result: EnvironmentGenerationWorker.TerrainGenerationResult):
		var biomes_texture = ImageTexture.create_from_image(result.biomes_image)
		instance.set_terrain(result.mesh, result.collider, biomes_texture, result.paths_image)

		var terrain_size = terrain_scale * terrain_subdivisions

		# Init per-chunk-source shaders.
		instance.foliage_source_shaders = [] as Array[ShaderMaterial]
		for source in _foliage_sources:
			var shader_mat = source.shader.duplicate()
			shader_mat.set_shader_parameter("biomes", biomes_texture)
			shader_mat.set_shader_parameter("terrain_size", terrain_size)
			shader_mat.set_shader_parameter("terrain_offset", Vector2(instance.global_position.x, instance.global_position.z))
			instance.foliage_source_shaders.push_back(shader_mat)

		_populate_objects(instance)
		_generate_foliage_chunks(instance, instance.rand.randi())

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

func _populate_objects(parent_terrain: TerrainChunk):
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

func populate_foliage(instance: FoliageChunk):
	var terrain_size = terrain_scale * terrain_subdivisions
	var chunk_size = terrain_size / foliage_chunk_count

	for i in _foliage_sources.size():
		var source = _foliage_sources[i]

		var pass_nodes = source.get_passes()
		var passes: Array[EnvironmentGenerationWorker.FoliagePopulationPass] = []
		for pass_node in pass_nodes:
			var worker_pass = EnvironmentGenerationWorker.FoliagePopulationPass.new()
			worker_pass.density_sampler = pass_node.density_noise.sampler()
			worker_pass.density_cutoff = pass_node.density_cutoff
			worker_pass.samples = pass_node.placement_samples

			passes.push_back(worker_pass)

		var params = EnvironmentGenerationWorker.FoliagePopulationParams.new()
		params.passes = passes
		params.gen_seed = instance.gen_seed
		params.height_sampler = _height_sampler
		params.global_position = instance.global_position
		params.terrain_scale = terrain_scale
		params.terrain_subdivisions = terrain_subdivisions
		params.chunk_size = chunk_size
		params.paths_image = instance.parent_terrain.paths_image
		params.terrain_global_position = instance.parent_terrain.global_position
		params.biomes_texture = instance.parent_terrain.biomes_texture
		params.shader = instance.parent_terrain.foliage_source_shaders[i]
		params.scale_max = source.scale_max
		params.scale_min = source.scale_min
		params.slope_limit = source.slope_limit
		params.instance_mesh = source.instance_mesh

		var on_ready = func (mesh: MultiMeshInstance3D):
			instance.apply_population(mesh)

		_worker.request_foliage_population(params, on_ready)
