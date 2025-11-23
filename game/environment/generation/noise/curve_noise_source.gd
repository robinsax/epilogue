@tool
class_name CurveNoiseSource extends AdditiveNoiseSource

@export var curve: Curve = null

class CurveNoiseSourceSampler extends NoiseSourceSampler:
	var additive: NoiseSourceSampler
	var curve: Curve

	func sample(offset: Vector2) -> float:
		return curve.sample(additive.sample(offset))

func sampler() -> NoiseSourceSampler:
	var instance = CurveNoiseSourceSampler.new()
	instance.additive = super.sampler()
	instance.curve = curve

	return instance
