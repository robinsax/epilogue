@tool
class_name AdditiveNoise extends SourceNoise

func sample(x: int, z: int) -> float:
	var value = 0.0
	var children = get_children()
	for child in children:
		value += child.sample(x, z)

	return value
