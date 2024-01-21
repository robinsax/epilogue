extends RigidBody3D

var item_name = "<unset>"

var active_inventory = null # server only

func _ready():
	pass

func _process(delta):
	pass

func get_character_interact_info():
	return item_name

func character_interact(character):
	_trigger_add_to_inventory.rpc(character.inventory.get_path())

@rpc("any_peer")
func _trigger_add_to_inventory(path: String):
	print("trigger ati")
	if not multiplayer.is_server():
		return

	_add_to_inventory.rpc(path)

@rpc("call_local", "authority")
func _add_to_inventory(path: String):
	print("broadcast ati")

	var inventory = get_node(path)
	inventory.insert_item_from_rpc(self)

func set_in_inventory_from_inventory(inv):
	$collider/mesh.set_layer_mask_value(2, inv)

	set_collision_mask_value(1, !inv)
	set_collision_mask_value(2, !inv)
	
	set_collision_layer_value(2, !inv)
	set_collision_layer_value(3, inv)
