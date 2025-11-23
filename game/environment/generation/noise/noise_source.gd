@tool
class_name NoiseSource extends Node

@export_tool_button("Visualize") var visualize_action = visualize 

func before_sampling(gen_seed: int):
	for child in get_children():
		child.before_sampling(gen_seed)

func sampler() -> NoiseSourceSampler:
	return NoiseSourceSampler.new()

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
