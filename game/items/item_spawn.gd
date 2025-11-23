@tool
class_name ItemSpawn extends Node3D

@export var pool_key: String = ""
@export var roll_modifier: float = 1.0

var _time: float = 1.0

func _process(delta):
	if _time > 0.0:
		_time -= delta
		if _time <= 0.0:
			_maybe_spawn()

func _maybe_spawn():
	if not Engine.is_editor_hint() and not is_multiplayer_authority():
		return

	var roll_result = LootTable.roll_one(pool_key, roll_modifier)
	if roll_result == null:
		return

	var item = roll_result.instantiate()
	if World.current == null and get_tree().edited_scene_root is EnvironmentGenerator:
		# In editor.
		add_child(item)
		item.owner = get_tree().edited_scene_root
		return

	World.current.spawn_item(item, global_position)
