@tool
class_name DirectNoise extends SourceNoise

@export var noise: FastNoiseLite = null
@export var scale: float = 1.0
@export var base: float = 0.0

func before_sampling(seed: int):
	super.before_sampling(seed)

	noise.seed = seed

func sample(x: int, z: int) -> float:
	return (noise.get_noise_2d(x, z) + base) * scale
