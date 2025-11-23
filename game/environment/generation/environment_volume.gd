@tool
class_name EnvironmentVolume extends Area3D

var populate_distance: float = 0.0
var gen_seed: int = 0
var generator: EnvironmentGenerator = null

var _is_populated: bool = false

func init_volume(set_generator: EnvironmentGenerator, size: Vector3, set_gen_seed: int, set_populate_distance: float):
	generator = set_generator
	gen_seed = set_gen_seed
	populate_distance = set_populate_distance

	var shape_node: CollisionShape3D = get_node("Shape")
	shape_node.shape = BoxShape3D.new()
	shape_node.shape.size = size
	shape_node.position = Vector3(size.x * 0.5, 0.0, size.z * 0.5)

func populate_volume():
	pass

func update_volume_state(observer_distance: float):
	if observer_distance < populate_distance and not _is_populated:
		_is_populated = true
		populate_volume()
