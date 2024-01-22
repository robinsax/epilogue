@tool

extends Node3D

@export var pool := "misc" :
	set(pool):
		if Engine.is_editor_hint() and _hint != null:
			_hint.set_text(pool)

var _hint = null

func _ready():
	if Engine.is_editor_hint():
		_hint = load("res://meta/editor_hint.tscn").instantiate()
		_hint.set_text(pool)
		add_child(_hint)
