@tool
class_name EnvironmentPathSource extends Node

@export var noise: NoiseSource = null
@export var band_min: float = 0.5
@export var band_max: float = 0.52

class ResolverParams:
	var offset: Vector2
	var terrain_subdivisions: int
	var terrain_scale: float
	var height_sampler: NoiseSource.Sampler
	var rand: RandomNumberGenerator

class Resolver:
	var noise_sampler: NoiseSource.Sampler
	var band_min: float
	var band_max: float

	func update_image(image: Image, component: int, params: ResolverParams) -> Image:
		for x in params.terrain_subdivisions:
			for z in params.terrain_subdivisions:
				var sample = noise_sampler.sample(params.offset + (Vector2(x, z) * params.terrain_scale))

				if sample > 0.5 and sample < 0.52:
					var pixel = image.get_pixel(x, z)
					if component == 0:
						pixel.r = 1.0
					elif component == 1:
						pixel.g = 1.0
					else:
						pixel.b = 1.0
					image.set_pixel(x, z, pixel)

		return image

func resolver() -> Resolver:
	var instance = Resolver.new()
	instance.noise_sampler = noise.sampler()
	instance.band_min = band_min
	instance.band_max = band_max

	return instance
