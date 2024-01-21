extends Node3D

var MAX_CLIENTS = 8

# todo private these
var net = null
var level = null
var players = null # server only, deferred
var _items = null # server only, deferred
var splash_ui = null
var _factory = null

var _profiles = {}
var _match_data = null

var client_profile_id = null

func _ready():
	net = $net
	level = $level
	_factory = $factory
	
	if DisplayServer.get_name() == "headless":
		_server_init()
	else:
		_client_init()

func _process(delta):
	pass

func server_profile_id(conn_id):
	return _profiles[conn_id]

func _server_init():
	print("server init")
	var port = int(OS.get_environment("PORT"))

	var match_data_path = OS.get_environment("MATCH_DATA_PATH")
	if FileAccess.file_exists(match_data_path):
		var file = FileAccess.open(match_data_path, FileAccess.READ)
		_match_data = JSON.parse_string(file.get_as_text())
		print("loaded match data ", _match_data)

	multiplayer.peer_connected.connect(_server_client_connected)
	multiplayer.peer_disconnected.connect(_server_client_disconnected)

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_CLIENTS)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err boot multiplayer server")
		return

	multiplayer.multiplayer_peer = peer

	_server_change_level.call_deferred(load("res://levels/match.tscn"))

func _server_client_connected(id):
	print("client conn ", id, " awaiting bind")

func _server_client_disconnected(id):
	print("client deconn ", id)

	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()

func _remove_level():
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()

func _server_change_level(scene):
	level.add_child(scene.instantiate())

	players = $level/level_root/players
	_items = $level/level_root/items

@rpc("any_peer")
func _server_bind_profile(conn_id, profile_id):
	if not multiplayer.is_server():
		return

	if conn_id in _profiles:
		print('err double bind conn')
		return

	print("bind ", conn_id, " to profile ", profile_id)
	_profiles[conn_id] = profile_id
	
	var character = preload("res://characters/test_player.tscn").instantiate()
	character.player = conn_id
	character.position = Vector3(10 * randf(), 0, 10 * randf())
	character.name = str(conn_id)
	players.add_child(character, true)
	
	if _match_data != null:
		var items = _match_data["items"]
		
		var owned_items = []
		for item in items:
			if item["attachment"][0] == profile_id:
				owned_items.append(item)
		
		_factory.spawn_items(_items, character, owned_items)

	print("spawned player and items")

func _client_init():
	splash_ui = load("res://ui/splash.tscn").instantiate()
	add_child(splash_ui)
	
	var direct_conn = OS.get_environment("DIRECT_CONNECT")
	if direct_conn != "":
		client_profile_id = net.client_name
		remove_child(splash_ui)

		client_join_match({ 'address': direct_conn })
	else:
		net.make_req("/profile", HTTPClient.METHOD_GET, _client_profile_loaded)

func _client_profile_loaded(profile_data):
	client_profile_id = profile_data["id"]

	var home = load("res://levels/home.tscn").instantiate()
	home.bind_profile(profile_data)

	level.add_child(home)
	remove_child(splash_ui)

func client_join_match(match_data):
	print("joining match ", match_data)

	_remove_level()
	
	multiplayer.connected_to_server.connect(_client_connected)

	var address_parts = match_data["address"].split(":")
	var host = address_parts[0]
	var port = int(address_parts[1])
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err establish conn")
		return

	multiplayer.multiplayer_peer = peer
	
	print("conn init")

func _client_connected():
	_server_bind_profile.rpc(multiplayer.get_unique_id(), client_profile_id)
	print("conn up and bound")
