@tool
class_name KernelBlendNoiseSource extends NoiseSource

@export var kernel_size: float = 1.0
@export var bleed_max: bool = false
@export var source: NoiseSource = null

class Sampler extends NoiseSource.Sampler:
	var source: NoiseSource.Sampler
	var bleed_max: bool
	var kernel_size: float

	func sample(offset: Vector2) -> float:
		var kernel = [
			source.sample(offset),
			source.sample(offset + Vector2(kernel_size, 0.0)),
			source.sample(offset + Vector2(kernel_size, kernel_size)),
			source.sample(offset + Vector2(0.0, kernel_size)),
			source.sample(offset + Vector2(-kernel_size, 0.0)),
			source.sample(offset + Vector2(-kernel_size, -kernel_size)),
			source.sample(offset + Vector2(0.0, -kernel_size)),
			source.sample(offset + Vector2(kernel_size, -kernel_size)),
			source.sample(offset + Vector2(-kernel_size, kernel_size))
		]

		var value = 0.0
		for sample in kernel:
			if bleed_max:
				value = max(value, sample)
			else:
				value += sample

		if bleed_max:
			return value
		return value / 9.0

func before_sampling(gen_seed: int):
	source.before_sampling(gen_seed)

func sampler() -> NoiseSource.Sampler:
	var instance = KernelBlendNoiseSource.Sampler.new()
	instance.source = source.sampler()
	instance.kernel_size = kernel_size
	instance.bleed_max = bleed_max

	return instance
