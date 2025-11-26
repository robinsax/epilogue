@tool
class_name FlameLight extends OmniLight3D

func _process(delta: float):
	light_energy = clamp(light_energy + ((0.5 - randf()) * 50.0 * delta), 1.0, 5.0);
