@tool
class_name AdditiveNoiseSource extends NoiseSource

class Sampler extends NoiseSource.Sampler:
	var samplers: Array[NoiseSource.Sampler]

	func sample(offset: Vector2) -> float:
		var value = 0.0
		for child in samplers:
			value += child.sample(offset)

		return value

func before_sampling(gen_seed: int):
	for source in get_children():
		source.before_sampling(gen_seed)

func sampler() -> NoiseSource.Sampler:
	var instance = AdditiveNoiseSource.Sampler.new()
	instance.samplers = [] as Array[NoiseSource.Sampler]
	for source in get_children():
		instance.samplers.push_back(source.sampler())

	return instance
