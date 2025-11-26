@tool
class_name NoiseSource extends Node

@export_tool_button("Visualize") var visualize_action = visualize 

class Sampler extends Object:
	func sample(_offset: Vector2) -> float:
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

func before_sampling(gen_seed: int):
	for child in get_children():
		child.before_sampling(gen_seed)

func sampler() -> NoiseSource.Sampler:
	return NoiseSource.Sampler.new()

func visualize():
	var parent = get_parent()
	while not parent is EnvironmentGenerator:
		parent = parent.get_parent()

	var image = sampler().to_image(
		Vector2(parent.global_position.x, parent.global_position.z),
		parent.terrain_scale, parent.terrain_subdivisions
	)

	var plane = PlaneMesh.new()
	plane.size = Vector2.ONE
	var material = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	plane.material = material

	var instance = MeshInstance3D.new()
	instance.mesh = plane
	instance.scale = Vector3(200.0, 1.0, 200.0)
	instance.position = Vector3(100.0, 50.0, 100.0)

	parent.add_child(instance)
	instance.owner = get_tree().edited_scene_root
