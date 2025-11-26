@tool
class_name TerrainChunk extends Node3D

var generator: EnvironmentGenerator
var is_root: bool
var gen_seed: int
var rand: RandomNumberGenerator
var biomes_texture: Texture2D
var paths_image: Image
var foliage_source_shaders: Array[ShaderMaterial]

var _is_populated: bool
var _nav_region: NavigationRegion3D
var _objects_root: Node3D
var _foliage_root: Node3D
var _mesh: MeshInstance3D
var _static_objects: Array[Node3D]

func _ready():
	_nav_region = $NavRegion
	_objects_root = $NavRegion/Objects
	_foliage_root = $Foliage
	_mesh = $NavRegion/Mesh

	for chunk in _foliage_root.get_children():
		chunk.parent_terrain = self

	_nav_region.navigation_mesh = NavigationMesh.new()

func regenerate_navigation():
	if _nav_region.bake_finished.is_connected(regenerate_navigation):
		_nav_region.bake_finished.disconnect(regenerate_navigation)

	_nav_region.bake_navigation_mesh()

func set_terrain(
	mesh: Mesh, collider: CollisionObject3D, biomes: Texture2D, paths: Image
):
	_mesh.mesh = mesh

	_mesh.add_child(collider)
	collider.owner = get_tree().edited_scene_root
	collider.collision_layer = CollisionLayers.FAST_GROUND | CollisionLayers.PHYSICAL
	collider.collision_mask = 0
	collider.position = (
		Vector3(1.0, 0.0, 1.0) * generator.terrain_scale * generator.terrain_subdivisions * 0.5
	)

	biomes_texture = biomes
	paths_image = paths

func _discover_static_objects(root: Node3D, max_depth: int = 3):
	if root is StaticObject:
		for inner in root.process_objects:
			_static_objects.push_back(inner)

	if max_depth == 0:
		return

	for child in root.get_children():
		if child is Node3D:
			_discover_static_objects(child, max_depth - 1)

func add_objects(node: Node3D):
	_discover_static_objects(node)

	_objects_root.add_child(node)
	node.owner = get_tree().edited_scene_root

	if _nav_region.is_baking():
		_nav_region.bake_finished.connect(regenerate_navigation)
	else:
		regenerate_navigation()

func add_foliage(chunk: FoliageChunk):
	_foliage_root.add_child(chunk)
	chunk.owner = get_tree().edited_scene_root

func update_cull_state(observer_position: Vector3):
	var center_position = (
		global_position +
		(Vector3(1.0, 0.0, 1.0) * generator.terrain_subdivisions * generator.terrain_scale * 0.5)
	)
	var observer_distance = (center_position - observer_position).length()

	Stats.stats["so/reg"] += _static_objects.size()

	if not _is_populated and observer_distance < generator.terrain_generate_distance:
		_is_populated = true
		generator.populate_terrain(self)

	_objects_root.visible = observer_distance < generator.objects_cull_distance
	if _objects_root.visible:
		Stats.stats["o/active"] += 1
	else:
		Stats.stats["o/culled"] += 1

	_mesh.visible = observer_distance < generator.terrain_cull_distance
	if _mesh.visible:
		Stats.stats["t/active"] += 1
	else:
		Stats.stats["t/culled"] += 1

	if _objects_root.visible and _mesh.visible:
		for foliage in _foliage_root.get_children():
			foliage.update_cull_state(observer_position)

		for object in _static_objects:
			object.set_process(_objects_root.visible)
