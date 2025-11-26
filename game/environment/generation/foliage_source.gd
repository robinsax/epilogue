@tool
class_name FoliageSource extends Node

@export var instance_mesh: Mesh = null
@export var shader: ShaderMaterial = null
@export var slope_limit: float = 0.6
@export var scale_min: float = 0.0
@export var scale_max: float = 1.0

func get_passes() -> Array[FoliageSourcePass]:
	var passes: Array[FoliageSourcePass] = []
	for child in get_children():
		if child is FoliageSourcePass:
			passes.push_back(child)

	return passes
