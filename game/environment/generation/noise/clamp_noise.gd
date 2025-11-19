@tool
class_name ClampNoise extends AdditiveNoise

@export var threshold: float = 0.5
@export var falloff: float = 0.0

func sample(x: int, z: int) -> float:
	var value = super.sample(x, z)

	if value < threshold:
		value = value * falloff

	return value
