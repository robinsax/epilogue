class_name QuadInterpolatedSampler extends Object

var height_sampler: NoiseSource.Sampler
var terrain_scale: float

func sample(sample_point: Vector2) -> float:
	var x0 = int(floor(sample_point.x))
	var x1 = x0 + 1
	var z0 = int(floor(sample_point.y))
	var z1 = z0 + 1

	var h00 = height_sampler.sample(Vector2(x0, z0))
	var h10 = height_sampler.sample(Vector2(x1, z0))
	var h01 = height_sampler.sample(Vector2(x0, z1))
	var h11 = height_sampler.sample(Vector2(x1, z1))

	var fx = sample_point.x - floor(sample_point.x)
	var fz = sample_point.y - floor(sample_point.y)

	var h0 = lerpf(h00, h10, fx)
	var h1 = lerpf(h01, h11, fx)

	# Correct some minor floating:
	return lerpf(h0, h1, fz) - 0.025

func sample_slope(sample_point: Vector2) -> float:
	var cell_size = terrain_scale
	var sample_offset = cell_size * 0.5

	var h_right = sample(sample_point + Vector2(sample_offset, 0))
	var h_left = sample(sample_point + Vector2(-sample_offset, 0))
	var h_forward = sample(sample_point + Vector2(0, sample_offset))
	var h_back = sample(sample_point + Vector2(0, -sample_offset))

	var dx = (h_right - h_left) / (sample_offset * 2.0)
	var dz = (h_forward - h_back) / (sample_offset * 2.0)
	
	var normal = Vector3(-dx, 1.0, -dz).normalized()
	
	var slope_angle = acos(normal.dot(Vector3.UP))	
	return slope_angle
