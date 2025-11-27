@tool
class_name BugCharacterSpawn extends Node3D

static var _BUG = load("res://characters/bug/bug_character_shell.tscn")

var _time: float = 1.0

func _process(delta):
	if _time > 0.0:
		_time -= delta
		if _time <= 0.0:
			_spawn()

func _spawn():
	if not Engine.is_editor_hint() and not is_multiplayer_authority():
		return

	var instance = _BUG.instantiate()

	if World.current == null and get_tree().edited_scene_root is EnvironmentGenerator:
		# In editor.
		add_child(instance)
		instance.owner = get_tree().edited_scene_root
		instance.position += Vector3.UP * 1.5
		return

	World.current.spawn_character(instance, global_position + (Vector3.UP * 3.0))
