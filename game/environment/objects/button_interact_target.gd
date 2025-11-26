class_name ButtonInteractTarget extends ObjectInteractTarget

var button_press_callback: Callable = Callable()

var _button_node: Node3D
var _sound: ClippedAudioPlayer
var _is_down: bool

func _ready():
	_button_node = $Button
	_sound = $Sound

	default_interaction = _on_interact

func _on_interact(character: Character):
	if not _is_down:
		_press_rpc.rpc()

@rpc("any_peer", "call_local")
func _press_rpc():
	var offset = Vector3(-0.02, 0.0, 0.0)

	if not button_press_callback.is_null():
		button_press_callback.call()
	_button_node.position += offset
	_is_down = true
	_sound.play_clip(0)

	await get_tree().create_timer(0.1).timeout

	_is_down = false
	_button_node.position -= offset
