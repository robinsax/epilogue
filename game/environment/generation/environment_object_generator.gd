@tool
class_name EnvironmentObjectGenerator extends Object

class Params:
	var base_position: Vector3
	var rand: RandomNumberGenerator
	var height_sampler: NoiseSourceSampler
	var ground_sampler: QuadInterpolatedSampler
	var biome_samplers: Array[NoiseSourceSampler]
	var terrain_scale: float

class Result:
	var node: Node3D
	var radius: float

func generate(params: Params) -> Result:
	return
