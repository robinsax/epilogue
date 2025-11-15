extends Node3D

var items = null
var players = null
var level_instance = null

func is_home(): # called during load_level add_child
	return $level_root.is_home

func player_for(profile_id): # called early on client
	for player in $level_root/players.get_children():
		if player.profile_id == profile_id:
			return player

	return null

func unload_level():
	for cur_level in get_children():
		remove_child(cur_level)
		cur_level.queue_free()
	
	level_instance = null
	items = null
	players = null

func load_level(inst):
	unload_level()

	add_child(inst)

	level_instance = $level_root
	items = $level_root/items
	players = $level_root/players
