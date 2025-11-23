class_name PerceptionVolume extends Area3D

var _current_state: Array[Node3D] = []

func _ready():
	_current_state = []

	body_entered.connect(_add_object)
	body_exited.connect(_remove_object)

func _add_object(object: Node3D):
	_current_state.push_back(object)

func _remove_object(object: Node3D):
	_current_state.remove_at(_current_state.find(object))

func get_perception() -> Array[Node3D]:
	return _current_state
