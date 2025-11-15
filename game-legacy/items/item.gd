extends RigidBody3D

@export var _item_data = {} # todo no, big traffic

var mesh = null
var collider = null
var _game = null
var _sync = null

var ATTACH_DELIM = ">"
@export var _attach_data = "" # packets break if this is an array

# peer isolated hydrations
var _prev_attach_data = ""
var _active_inventory = null
var _was_in_inventory = null

func bind_data(data):
	_item_data = data

func _ready():
	_game = get_node("/root/game")
	_sync = $sync
	collider= $collider
	mesh = $collider/mesh

func _update_attach():
	if _prev_attach_data == _attach_data:
		return
	_prev_attach_data = _attach_data
	
	if _active_inventory != null:
		_active_inventory.register_remove_as_effect(self)
		_active_inventory = null
	
	if _attach_data != "":
		var attach_parts = _attach_data.split(ATTACH_DELIM)

		_active_inventory = _game.level.player_for(attach_parts[0]).inventory
		_active_inventory.register_insert_as_effect(self, attach_parts[1])

func _process(delta):
	_update_attach()

	var in_inventory = _active_inventory != null
	if in_inventory:
		position = _active_inventory.slot_containing(self).global_position

	if in_inventory == _was_in_inventory:
		return

	_was_in_inventory = in_inventory
	
	# this is desired but breaks godot netcode
	#_sync.replication_config.property_set_sync(".:position", not in_inventory)
	#_sync.replication_config.property_set_sync(".:rotation", not in_inventory)

	mesh.set_layer_mask_value(2, in_inventory) # inventory_view render layer

	set_collision_mask_value(1, not in_inventory) # main collision mask
	set_collision_mask_value(2, not in_inventory) # item collision mask
	
	set_collision_layer_value(2, not in_inventory) # item collision layer
	set_collision_layer_value(3, in_inventory) # item_inventory collision layer

func _exit_tree():
	if _active_inventory != null:
		_active_inventory.register_remove_as_effect(self)

func interact_info():
	return _item_data["type"]["name"]

func interacted_by(character):
	inventory_attach(character.inventory)

func inventory_attach(inventory, slot_name=null):
	var inventory_ref = ""
	if inventory != null:
		inventory_ref = inventory.owner.name

		if slot_name == null:
			var slot = inventory.pick_slot_for(self)
			if not slot:
				print("no slot avail")
				return
			
			slot_name = slot.name
	
	if slot_name == null:
		slot_name = ""

	_trigger_inventory_attach.rpc(inventory_ref, slot_name)

@rpc("call_local", "any_peer")
func _trigger_inventory_attach(inventory_ref: String, slot_name: String):
	if not multiplayer.is_server():
		return

	# todo validate
	if inventory_ref == "":
		_attach_data = ""
	else:
		_attach_data = ATTACH_DELIM.join([inventory_ref, slot_name])

func data():
	var data = _item_data.duplicate(true)
	if _active_inventory != null:
		data.erase("position")
		data["attachment"] = _attach_data.split(">")
	else:
		data.erase("attachment")
		data["position"] = [position.x, position.y, position.z]
	return data
