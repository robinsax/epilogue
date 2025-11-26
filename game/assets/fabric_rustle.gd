class_name FabricRustle extends ClippedAudioPlayer

@export var occurence: float = 3.0

var _next_time: float

func _process(delta: float) -> void:
	if _next_time <= 0.0:
		play_random_clip(0, 7)
		_next_time = (occurence * randf())
	else:
		_next_time -= delta
