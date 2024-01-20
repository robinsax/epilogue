extends Node3D

var MAX_CLIENTS = 8

var util = load("res://util.gd").new()

var splash_ui = null

func _ready():
	util.bind(self)

	if DisplayServer.get_name() == "headless":
		_server_init()
	else:
		_client_init()

func _process(delta):
	pass

func _server_init():
	print("server init")
	var port = int(OS.get_environment("PORT"))

	multiplayer.peer_connected.connect(_server_client_connected)
	multiplayer.peer_disconnected.connect(_server_client_disconnected)

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_CLIENTS)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err boot multiplayer server")
		return

	multiplayer.multiplayer_peer = peer

	_server_change_level.call_deferred(load("res://levels/level.tscn"))

func _server_client_connected(id):
	print("client conn ", id)
	
	var character = preload("res://characters/test_player.tscn").instantiate()
	character.player = id
	character.position = Vector3(10 * randf(), 0, 10 * randf())
	character.name = str(id)
	$level/level_root/players.add_child(character, true)
	print("spawned")
	
func _server_client_disconnected(id):
	print("client deconn ", id)

	if not $level/level_root/players.has_node(str(id)):
		return
	$level/level_root/players.get_node(str(id)).queue_free()

func _server_change_level(scene):
	print("server change level")
	for c in $level.get_children():
		$level.remove_child(c)
		c.queue_free()
	
	$level.add_child(scene.instantiate())

func _client_init():
	splash_ui = load("res://ui/splash.tscn").instantiate()
	add_child(splash_ui)
	
	var direct_conn = OS.get_environment("DIRECT_CONNECT")
	if direct_conn != "":
		remove_child(splash_ui)

		_client_match_ready({
			'address': direct_conn
		})
	else:
		util.make_req("/profile", HTTPClient.METHOD_GET, _client_profile_loaded)

func _client_profile_loaded(data):
	print("profile: ", data)
	
	add_child(load("res://levels/base.tscn").instantiate())
	remove_child(splash_ui)

func client_join_match(match_id):
	print("join ", match_id)
	util.make_req("/match/" + match_id, HTTPClient.METHOD_GET, _client_match_ready)

func _client_match_ready(match_data):
	print("joining match ", match_data)
	
	var address_parts = match_data["address"].split(":")
	var host = address_parts[0]
	var port = int(address_parts[1])
	
	print(host, " ", port)
	
	multiplayer.connected_to_server.connect(_client_connected)

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err establish conn")
		return

	multiplayer.multiplayer_peer = peer
	
	print("conn init")

func _client_connected():
	print("conn up")
