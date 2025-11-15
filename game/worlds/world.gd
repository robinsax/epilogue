class_name World extends Node3D

var characters: Node3D
var characters_spawner: MultiplayerSpawner

signal prepared()

func _ready():
	characters = $Characters
	characters_spawner = $CharactersSpawner

	prepared.emit()
