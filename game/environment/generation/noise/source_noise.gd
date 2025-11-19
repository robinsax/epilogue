@tool
class_name SourceNoise extends Node

func before_sampling(seed: int):
	for child in get_children():
		child.before_sampling(seed)

func sample(x: int, z: int) -> float:
	return 0.0

func to_image(size: int, no_normalize: bool = false) -> Image:
	var image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var max = 1.0

	if not no_normalize:
		for x in size:
			for z in size:
				var value = sample(x, z)
				if value > max:
					max = value

	for x in size:
		for z in size:
			var value = sample(x, z) / max
			image.set_pixel(x, z, Color(value, value, value))

	return image
