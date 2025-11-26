@tool
class_name FoliageChunk extends Node3D

var parent_terrain: TerrainChunk
var gen_seed: int

var _meshes_root: Node3D
var _is_populated: bool
var _is_culled: bool

func _ready():
	_meshes_root = $Meshes

func update_cull_state(observer_position: Vector3):
	var observer_distance = (global_position - observer_position).length()

	var populate = (
		not _is_populated and
		observer_distance < parent_terrain.generator.foliage_generate_distance
	)
	if populate:
		_is_populated = true
		Stats.stats["f/pop"] += 1
		parent_terrain.generator.populate_foliage(self)

	_is_culled = observer_distance > parent_terrain.generator.foliage_cull_distance
	for child in _meshes_root.get_children():
		child.visible = not _is_culled

	if not _is_culled:
		Stats.stats["f/active"] += 1
	else:
		Stats.stats["f/culled"] += 1

func apply_population(mesh: MultiMeshInstance3D):
	_meshes_root.add_child(mesh)
	mesh.owner = get_tree().edited_scene_root

	mesh.visible = not _is_culled
