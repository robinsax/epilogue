extends RigidBody3D

@export var _data = {}

var active_inventory = null # server only

func bind_data(data):
	_data = data

func _ready():
	pass

func _process(delta):
	pass

func _exit_tree():
	if active_inventory != null:
		active_inventory.remove_item_from_destroy(self)

func to_data():
	var data = _data.duplicate(true)
	if active_inventory != null:
		data.erase("position")
		data["attachment"] = active_inventory.attachment_data_for_item(self)
	else:
		data.erase("attachment")
		data["position"] = [position.x, position.y, position.z]
	return data

func interact_info():
	return _data["type"]["name"]

func interact(character):
	_trigger_interact.rpc(character.inventory.get_path())

@rpc("call_local", "any_peer")
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
