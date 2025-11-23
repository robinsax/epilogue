@tool
class_name FoliageVolume extends EnvironmentVolume

var MAX_IMPACTORS = 8

@export var cull_distance: float = 60.0

var source: FoliageSource = null
var parent_terrain: TerrainVolume = null

var _culled: bool = true
var _mesh: MultiMeshInstance3D = null
var _impactors: Array[Node3D] = []
var _impactors_changed: bool = false

func _get_mesh() -> MultiMeshInstance3D:
	if _mesh == null:
		_mesh = get_node("MultiMesh")

	return _mesh

func _ready():
	body_entered.connect(_add_impactor)
	body_exited.connect(_remove_impactor)

func _process(delta):
	if source == null or _culled:
		return

	var mesh = _get_mesh()
	for i in MAX_IMPACTORS:
		var value = Vector3.ZERO
		if _impactors.size() > i:
			value = _impactors[i].global_position
		elif not _impactors_changed:
			break

		mesh.set_instance_shader_parameter("world_impactor_" + str(i), value)

	_impactors_changed = false

func _add_impactor(node: Node3D):
	_impactors_changed = true
	_impactors.push_back(node)

func _remove_impactor(node: Node3D):
	_impactors_changed = false
	_impactors.remove_at(_impactors.find(node))

func update_volume_state(observer_distance: float):
	super.update_volume_state(observer_distance)

	_culled = observer_distance > cull_distance
	_get_mesh().visible = not _culled

func populate_volume():
	generator.populate_foliage(self)

func apply_population(
	transforms: Array[Transform3D], biomes: Texture2D,
	terrain_global_position: Vector3, terrain_size: float
):
	var shape: Shape3D = get_node("Shape").shape
	var size = shape.size.z / 2.0

	var multimesh_node: MultiMeshInstance3D = get_node("MultiMesh")
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = source.instance_mesh
	multimesh_node.multimesh = multimesh

	if source.instance_shader:
		var mesh_shader = ShaderMaterial.new()
		mesh_shader.shader = source.instance_shader
		mesh_shader.set_shader_parameter("biomes", biomes)
		mesh_shader.set_shader_parameter("terrain_size", terrain_size)
		mesh_shader.set_shader_parameter("terrain_offset", terrain_global_position)
		multimesh.mesh.surface_set_material(0, mesh_shader)
	else:
		multimesh.mesh.surface_set_material(0, source.instance_material)

	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i]) 
