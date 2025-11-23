@tool
class_name SimpleEnvironmentObjectSource extends EnvironmentObjectSource

@export var prefab: Resource = null
@export var min_scale: float = 1.0
@export var max_scale: float = 1.0
@export var exclusion_radius: float = 1.0

class Generator extends EnvironmentObjectGenerator:
	var prefab: Resource
	var min_scale: float
	var max_scale: float
	var exclusion_radius: float

	func generate(params: EnvironmentObjectGenerator.Params) -> EnvironmentObjectGenerator.Result:
		var instance = prefab.instantiate()

		var scale = min_scale + (params.rand.randf() * (max_scale - min_scale))
		instance.scale = Vector3(1.0, 1.0, 1.0) * scale
		instance.rotation = Vector3(0.0, params.rand.randf() * PI * 2, 0.0)

		var result = EnvironmentObjectGenerator.Result.new()
		result.node = instance
		result.radius = exclusion_radius

		return result

func generator() -> EnvironmentObjectGenerator:
	var instance = Generator.new()
	instance.prefab = prefab
	instance.max_scale = max_scale
	instance.min_scale = min_scale
	instance.exclusion_radius = exclusion_radius

	return instance
