extends Node3D

var _game = null

func _ready():
	_game = get_node("/root/game")

func spawn_items(item_list, character=null): # todo rework
	for item_data in item_list:
		print("spawn ", item_data)
		
		var res_path = "res://items/" + item_data["type"]["archetype"] + ".tscn"
		print("res path ", res_path)

		var item = load(res_path).instantiate()
		item.bind_data(item_data)
		item.name = item_data["id"]
		_game.level.items.add_child(item, true)

		if "position" in item_data:
			var pos_data = item_data["position"]
			item.position = Vector3(pos_data[0], pos_data[1], pos_data[2])
		elif "attachment" in item_data:
			var attach_data = item_data["attachment"]
			
			item.inventory_attach(character.inventory, attach_data[1])

func spawn_player(position, profile_id):
	var player = load("res://characters/test_player.tscn").instantiate()
	player.position = position
	player.profile_id = profile_id
	player.name = profile_id
	_game.level.players.add_child(player, true)
	
	return player
