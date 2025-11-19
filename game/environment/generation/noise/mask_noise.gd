@tool
class_name MaskNoise extends SourceNoise

@export var source: SourceNoise = null
@export var mask: SourceNoise = null
@export var cutoff: float = 0.5
@export var negative: bool = false
@export var masked_value: float = 0.0
@export var additive_mask: bool = false

func sample(x: int, z: int) -> float:
	var mask_value = mask.sample(x, z)
	var source_value = source.sample(x, z)

	if negative:
		if mask_value < cutoff:
			return source_value
	else:
		if mask_value > cutoff:
			return source_value

	if additive_mask:
		return masked_value + source_value

	return masked_value
