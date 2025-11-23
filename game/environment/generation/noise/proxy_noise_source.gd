@tool
class_name ProxyNoiseSource extends NoiseSource

@export var to: NoiseSource = null
@export var scale: float = 1.0

class ProxyNoiseSourceSampler extends NoiseSourceSampler:
	var to: NoiseSourceSampler
	var scale: float

	func sample(offset: Vector2) -> float:
		return to.sample(offset) * scale

func before_sampling(gen_seed: int):
	to.before_sampling(gen_seed)

func sampler():
	var instance = ProxyNoiseSourceSampler.new()
	instance.to = to.sampler()
	instance.scale = scale

	return instance
