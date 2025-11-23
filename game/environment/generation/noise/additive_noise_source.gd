@tool
class_name AdditiveNoiseSource extends NoiseSource

class AdditiveNoiseSourceSampler extends NoiseSourceSampler:
	var samplers: Array[NoiseSourceSampler]

	func sample(offset: Vector2) -> float:
		var value = 0.0
		for child in samplers:
			value += child.sample(offset)

		return value

func before_sampling(gen_seed: int):
	for source in get_children():
		source.before_sampling(gen_seed)

func sampler() -> NoiseSourceSampler:
	var instance = AdditiveNoiseSourceSampler.new()
	instance.samplers = [] as Array[NoiseSourceSampler]
	for source in get_children():
		instance.samplers.push_back(source.sampler())

	return instance
