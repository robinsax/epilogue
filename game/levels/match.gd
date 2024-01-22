extends Node3D

var _game = null

var is_home = false

signal generated()

func _ready():
	_game = get_node("/root/game")
	
	if multiplayer.is_server():
		_generate()

func _generate():
	print("collecting item pool")
	var match_id = OS.get_environment("MATCH_ID")
	var loot_spawns = get_tree().get_nodes_in_group("loot_spawns")
	
	var pool_request = []
	for spawner in loot_spawns:
		var pos = spawner.global_position
		pool_request.append({
			'pool': spawner['pool'],
			'position': [pos.x, pos.y, pos.z]
		})
		
	_game.net.make_req(
		"/match/" + match_id + "/item-pool",
		HTTPClient.METHOD_POST,
		_item_pool_resolved,
		pool_request
	)

func _item_pool_resolved(result_data):
	_game.factory.spawn_items(result_data["items"])
	
	print("pool resolved")
	
	generated.emit()
