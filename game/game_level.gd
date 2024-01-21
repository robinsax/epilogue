extends Node3D

var items = null
var players = null
var level_instance = null

func unload_level():
	for cur_level in get_children():
		remove_child(cur_level)
		cur_level.queue_free()
	
	level_instance = null
	items = null
	players = null

func load_level(res):
	unload_level()

	add_child(res.instantiate())

	level_instance = $level_root
	items = $level_root/items
	players = $level_root/players
