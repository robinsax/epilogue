extends Node3D

var _factory = null
var _net = null
var _connector = null

var _profile_data = null

var _items = null

var _saving = false

func bind_profile(profile_data):
	_profile_data = profile_data

func _ready():
	_items = $items
	_net = get_node("/root/game/net")
	_factory = get_node("/root/game/factory")
	_connector = get_node("/root/game/connector")

	_factory.spawn_items(_items, $test_player, _profile_data["items"])

func _process(delta):
	if Input.is_action_pressed("debug"):
		_save_profile()

func _save_profile():
	if _saving:
		return
	_saving = true

	var item_data = []
	for item in _items.get_children():
		item_data.append(item.to_data())
		
	var data = { "items": item_data }

	_net.make_req("/profile", HTTPClient.METHOD_PATCH, _profile_saved, data)

func _profile_saved(data):
	print("profile saved")
	_saving = false

func queue():
	var equipped_items = $test_player.inventory.items()
	
	var item_list = []
	for item in equipped_items:
		item_list.append(item.to_data())
	
	_connector.queue(item_list)

	for item in equipped_items:
		item.queue_free()
