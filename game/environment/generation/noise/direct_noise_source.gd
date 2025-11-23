@tool
class_name DirectNoiseSource extends NoiseSource

@export var noise: FastNoiseLite = null
@export var scale: float = 1.0
@export var base: float = 0.0

class DirectNoiseSourceSampler extends NoiseSourceSampler:
	var noise: FastNoiseLite
	var scale: float
	var base: float
	
	func sample(offset: Vector2) -> float:
		var norm = (noise.get_noise_2d(offset.x, offset.y) + 1.0) * 0.5
		return (norm + base) * scale

func before_sampling(gen_seed: int):
	noise.seed = gen_seed

func sampler() -> NoiseSourceSampler:
	var instance = DirectNoiseSourceSampler.new()
	instance.noise = noise.duplicate()
	instance.scale = scale
	instance.base = base

	return instance
