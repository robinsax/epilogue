class_name Possession extends Node3D

var character: Character = null

func _ready():
	character = get_parent()

func is_authority():
	return false
