@tool
class_name MaskNoiseSource extends NoiseSource

@export var source: NoiseSource = null
@export var mask: NoiseSource = null
@export var cutoff: float = 0.5
@export var negative: bool = false
@export var masked_value: float = 0.0
@export var additive_mask: bool = false

class Sampler extends NoiseSource.Sampler:
	var source: NoiseSource.Sampler
	var mask: NoiseSource.Sampler
	var cutoff: float
	var negative: bool
	var masked_value: float
	var additive_mask: bool

	func sample(offset: Vector2) -> float:
		var mask_value = mask.sample(offset)
		var source_value = source.sample(offset)

		if negative:
			if mask_value < cutoff:
				return source_value
		else:
			if mask_value > cutoff:
				return source_value

		if additive_mask:
			return masked_value + source_value

		return masked_value

func before_sampling(gen_seed: int):
	mask.before_sampling(gen_seed)
	source.before_sampling(gen_seed)

func sampler() -> NoiseSource.Sampler:
	var instance = MaskNoiseSource.Sampler.new()
	instance.source = source.sampler()
	instance.mask = mask.sampler()
	instance.cutoff = cutoff
	instance.negative = negative
	instance.masked_value = masked_value
	instance.additive_mask = additive_mask

	return instance
