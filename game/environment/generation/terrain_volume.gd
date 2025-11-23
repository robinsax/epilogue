@tool
class_name TerrainVolume extends EnvironmentVolume

var biomes_texture: Texture2D = null
var paths_image: Image = null
var is_root: bool = false

var _nav_region: NavigationRegion3D = null
var _objects_root: Node3D = null
var _shape: CollisionShape3D = null
var _mesh: MeshInstance3D = null

func _ready():
	_nav_region = $NavRegion
	_objects_root = $NavRegion/Objects
	_shape = $Shape
	_mesh = $NavRegion/Mesh

	_nav_region.navigation_mesh = _nav_region.navigation_mesh.duplicate()

func populate_volume():
	generator.populate_terrain(self)

func regenerate_navigation():
	_nav_region.bake_finished.disconnect(regenerate_navigation)

	_nav_region.bake_navigation_mesh()

func set_shape(shape: Shape3D):
	_shape.shape = shape

func set_terrain(
	mesh: Mesh, fast_collider: CollisionObject3D, slow_collider: CollisionObject3D, biomes: Texture2D,
	paths: Image
):
	_mesh.mesh = mesh

	_mesh.add_child(slow_collider)
	slow_collider.owner = get_tree().edited_scene_root
	slow_collider.collision_layer = CollisionLayerValues.SLOW_GROUND
	slow_collider.collision_mask = 0

	var shape: CollisionShape3D = fast_collider.get_children()[0]
	shape.debug_color = Color(1.0, 0.0, 0.0)
	shape.debug_fill = true
	_mesh.add_child(fast_collider)
	fast_collider.owner = get_tree().edited_scene_root

	fast_collider.position = Vector3(1.0, 0.0, 1.0) * _shape.shape.size.x * 0.5
	fast_collider.collision_layer = CollisionLayerValues.FAST_GROUND
	fast_collider.collision_mask = 0

	biomes_texture = biomes
	paths_image = paths

func add_objects(node: Node3D):
	_objects_root.add_child(node)
	node.owner = get_tree().edited_scene_root

	if _nav_region.is_baking():
		_nav_region.bake_finished.connect(regenerate_navigation)
	else:
		regenerate_navigation()
