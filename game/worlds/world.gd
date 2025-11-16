class_name World extends Node3D

var characters: Node3D
var items: Node3D

static var current: World = null

signal prepared()

func _ready():
	characters = $Characters
	items = $Items

	World.current = self

	prepared.emit()

func get_character(character_name: String) -> Character:
	return characters.get_node(character_name)
