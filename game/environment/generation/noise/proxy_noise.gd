@tool
class_name ProxyNoise extends SourceNoise

@export var to: SourceNoise = null
@export var scale: float = 1.0

func sample(x: int, z: int) -> float:
	return to.sample(x, z) * scale
