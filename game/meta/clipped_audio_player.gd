class_name ClippedAudioPlayer extends AudioStreamPlayer3D

@export var clip_length: float = 0.625
@export var clip_prestop: float = 0.1
@export var clip_padding: float = 0.2
@export var db_variance: float = 6.0

var _play_time: float
var _base_db: float

func _ready() -> void:
	_play_time = -clip_padding - 0.1
	_base_db = volume_db

func _process(delta: float) -> void:
	if _play_time <= 0.0:
		stop()
	if _play_time >= -clip_padding:
		_play_time -= delta

func play_clip(clip_index: int, replay_prevention: bool = false):
	if replay_prevention and _play_time > -clip_padding:
		return

	stop()
	volume_db = _base_db + ((randf() - 0.5) * db_variance)
	play(clip_index * clip_length)
	_play_time = clip_length - clip_prestop

func play_random_clip(clip_offset: int, count: int, replay_prevention: bool = false):
	var clip_index = randi_range(clip_offset, clip_offset + count - 1)
	play_clip(clip_index, replay_prevention)

@rpc("any_peer", "call_local")
func _play_clip_rpc(clip_index: int, replay_prevention: bool = false):
	play_clip(clip_index, replay_prevention)

func play_clip_rpc(clip_index: int, replay_prevention: bool = false):
	_play_clip_rpc.rpc(clip_index, replay_prevention)
