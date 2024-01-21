extends Node3D

func _ready():
	pass

func _process(delta):
	pass

func spawn_items(to_node, player, item_list):
	for item_data in item_list:
		print("spawn ", item_data)
		
		var res_path = "res://items/" + item_data["type"]["archetype"] + ".tscn"
		print("res path ", res_path)

		var item = load(res_path).instantiate()
		item.bind_data(item_data)
		item.name = item_data["id"]
		to_node.add_child(item, true)

		if "position" in item_data:
			var pos_data = item_data["position"]
			item.position = Vector3(pos_data[0], pos_data[1], pos_data[2])
		elif "attachment" in item_data:
			var attach_data = item_data["attachment"]
			item.interact(player) # todo no
