class_name World extends Node3D

var characters: Node3D
var items: Node3D
var projectiles: Node3D

static var current: World = null

signal prepared()

func _ready():
	characters = $Characters
	items = $Items
	projectiles = $Projectiles

	World.current = self

	prepared.emit()

func get_character(character_name: String) -> Character:
	return characters.get_node(character_name)

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
