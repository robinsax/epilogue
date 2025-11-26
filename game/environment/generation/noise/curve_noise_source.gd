@tool
class_name CurveNoiseSource extends AdditiveNoiseSource

@export var curve: Curve = null

class Sampler extends NoiseSource.Sampler:
	var additive: NoiseSource.Sampler
	var curve: Curve

	func sample(offset: Vector2) -> float:
		return curve.sample(additive.sample(offset))

func sampler() -> NoiseSource.Sampler:
	var instance = CurveNoiseSource.Sampler.new()
	instance.additive = super.sampler()
	instance.curve = curve

	return instance
