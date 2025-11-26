@tool
class_name ProxyNoiseSource extends NoiseSource

@export var to: NoiseSource = null
@export var scale: float = 1.0

class Sampler extends NoiseSource.Sampler:
	var to: NoiseSource.Sampler
	var scale: float

	func sample(offset: Vector2) -> float:
		return to.sample(offset) * scale

func before_sampling(gen_seed: int):
	to.before_sampling(gen_seed)

func sampler():
	var instance = ProxyNoiseSource.Sampler.new()
	instance.to = to.sampler()
	instance.scale = scale

	return instance
