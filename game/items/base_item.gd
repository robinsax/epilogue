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
	_trigger_interact.rpc(character.inventory.get_path())

@rpc("any_peer")
func _trigger_interact(path: String):
	if not multiplayer.is_server():
		return

	_do_interact.rpc(path)

@rpc("call_local", "authority")
func _do_interact(path: String):
	var inventory = get_node(path)
	if active_inventory == inventory:
		inventory.remove_item_from_rpc(self)
	else:
		inventory.insert_item_from_rpc(self)

func set_in_inventory_from_inventory(inv):
	$collider/mesh.set_layer_mask_value(2, inv) # inventory_view render layer

	set_collision_mask_value(1, !inv) # main collision mask
	set_collision_mask_value(2, !inv) # item collision mask
	
	set_collision_layer_value(2, !inv) # item collision layer
	set_collision_layer_value(3, inv) # item_inventory collision layer
