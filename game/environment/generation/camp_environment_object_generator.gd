@tool
class_name CampEnvironmentObjectSource extends EnvironmentObjectSource

@export var min_count: int = 1
@export var max_count: int = 10
@export var radius: float = 3.0
@export var exclusion_gapping: float = 1.2

class MemberPrefab:
	var prefab: Resource
	var chance: float

class Generator extends EnvironmentObjectGenerator:
	var members: Array[MemberPrefab]
	var centers: Array[MemberPrefab]
	var min_count: int
	var max_count: int
	var radius: float
	var exclusion_gapping: float

	func generate(params: EnvironmentObjectGenerator.Params) -> EnvironmentObjectGenerator.Result:
		var count = params.rand.randi_range(min_count, max_count)
		var root = Node3D.new()
		root.position = params.base_position

		if centers.size() > 0:
			for member in centers:
				if params.rand.randf() > member.chance:
					continue

				var instance = member.prefab.instantiate()
				root.add_child(instance)
				break

		for k in count:
			var instance: Node3D = null
			for member in members:
				if params.rand.randf() > member.chance:
					continue

				instance = member.prefab.instantiate()
				break

			if instance == null:
				continue

			var angle = (float(k) / count) * PI * 2
			instance.rotation = Vector3(0.0, angle, 0.0)

			var x = sin(angle) * radius
			var z = cos(angle) * radius
			var y = params.ground_sampler.sample(Vector2(
				params.base_position.x + x,
				params.base_position.z + z
			)) * params.terrain_scale

			root.add_child(instance)
			instance.position = Vector3(x, y - params.base_position.y, z)

		var result = EnvironmentObjectGenerator.Result.new()
		result.node = root
		result.radius = radius * exclusion_gapping

		return result

func _copy_member(node: CampMemberPrefab):
	var member = MemberPrefab.new()
	member.prefab = node.prefab
	member.chance = node.chance

	return member

func generator() -> EnvironmentObjectGenerator:
	var instance = Generator.new()
	instance.min_count = min_count
	instance.max_count = max_count
	instance.radius = radius
	instance.exclusion_gapping = exclusion_gapping

	instance.members = [] as Array[MemberPrefab]
	var center_root: Node = null
	for child in get_children():
		if child is CampMemberPrefab:
			instance.members.push_back(_copy_member(child))
		if child.name == "Center":
			center_root = child

	instance.centers = [] as Array[MemberPrefab]
	if center_root != null:
		for child in center_root.get_children():
			instance.centers.push_back(_copy_member(child))

	return instance
