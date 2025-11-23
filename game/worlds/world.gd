class_name World extends Node3D

var characters: Node3D
var items: Node3D
var projectiles: Node3D
var _generator: EnvironmentGenerator

static var current: World = null

signal prepared()

func _ready():
	characters = $Characters
	items = $Items
	projectiles = $Projectiles
	_generator = get_node_or_null("Static/EnvironmentGenerator")

	World.current = self

	if _generator == null:
		_report_prepared()
	else:
		_generator.root_terrain_ready.connect(_report_prepared)

func _report_prepared():
	prepared.emit()

func get_character(character_name: String) -> Character:
	return characters.get_node(character_name).character

func get_item(item_name: String) -> Item:
	return items.get_node(item_name)

@rpc("authority", "call_local", "reliable")
func kill_character(character_name: String):
	var character = get_character(character_name)

	characters.remove_child(character)

func spawn_projectile(projectile_type: Resource, global_pos: Vector3, global_rot: Vector3):
	var instance = projectile_type.instantiate()
	projectiles.add_child(instance, true)
	instance.global_position = global_pos
	instance.global_rotation = global_rot
	instance.is_cosmetic = not is_multiplayer_authority()

func spawn_character(character: Node3D, global_pos: Vector3):
	characters.add_child(character, true)
	character.global_position = global_pos

func spawn_item(item: Item, global_pos: Vector3):
	items.add_child(item, true)
	item.global_position = global_pos
