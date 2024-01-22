extends Node3D

var _game = null
var _player = null

var _saving = false
var _should_queue = false

var is_home = true

func _ready():
	_initialize.call_deferred()
	
func _initialize():
	_game = get_node("/root/game")

	var profile_data = _game.driver.profile_data()

	_player = _game.factory.spawn_player(Vector3(0.0, 0.0, 0.0), profile_data["id"])
	_game.factory.spawn_items(profile_data["items"], _player)

func _process(delta):
	if Input.is_action_pressed("debug"):
		_save_profile()

func _save_profile():
	# todo move to client driver
	if _saving:
		return
	_saving = true

	var item_data = []
	for item in _game.level.items.get_children():
		item_data.append(item.data())
		
	var data = { "items": item_data }
	_game.net.make_req("/profile", HTTPClient.METHOD_PATCH, _profile_saved, data)

func _profile_saved(data):
	print("profile saved")
	_saving = false
	
	if _should_queue:
		_should_queue = false
		var equipped_items = _player.inventory.items()

		var item_list = []
		for item in equipped_items:
			item_list.append(item.data())
		
		for item in equipped_items:
			item.queue_free()

		_game.connector.queue(item_list)

func queue():
	_should_queue = true
	_save_profile()
