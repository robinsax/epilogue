@tool
class_name EnvironmentObjectSource extends Node

@export var placements: int = 10

class GeneratorParams:
	var base_position: Vector3
	var rand: RandomNumberGenerator
	var height_sampler: NoiseSource.Sampler
	var ground_sampler: QuadInterpolatedSampler
	var biome_samplers: Array[NoiseSource.Sampler]
	var terrain_scale: float

class GeneratorResult:
	var node: Node3D
	var radius: float

class Generator extends Object:
	func generate(params: GeneratorParams) -> GeneratorResult:
		return GeneratorResult.new()

func generator() -> EnvironmentObjectSource.Generator:
	return EnvironmentObjectSource.Generator.new()
