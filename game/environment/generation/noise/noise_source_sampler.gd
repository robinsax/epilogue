@tool
class_name NoiseSourceSampler extends Object

func sample(offset: Vector2) -> float:
	return 0.0

func to_image(offset: Vector2, domain_scale: float, size: int) -> Image:
	var image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)

	var max_value = 1.0
	for x in size:
		for z in size:
			var point = offset + (Vector2(x, z) * domain_scale)
			var value = sample(point)
			if value > max_value:
				max_value = value

	for x in size:
		for z in size:
			var point = offset + (Vector2(x, z) * domain_scale)
			var value = sample(point) / max_value
			image.set_pixel(x, z, Color(value, value, value))

	return image
