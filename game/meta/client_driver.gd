extends Node3D

var _game = null
var _splash_ui = null

var _profile_id = null
var _profile_data = null # missing if direct connect

func profile_id():
	return _profile_id

func profile_data():
	return _profile_data

func initialize():
	_game = get_node("/root/game")

	_splash_ui = load("res://ui/splash.tscn").instantiate()
	add_child(_splash_ui)

	var direct_conn_addr = OS.get_environment("DIRECT_CONNECT")
	if direct_conn_addr != "":
		_profile_id = "foo"
		if OS.has_environment("PROFILE_ID"):
			_profile_id = OS.get_environment("PROFILE_ID")

		remove_child(_splash_ui)

		connect_to_match(direct_conn_addr)
	else:
		_game.net.make_req("/profile", HTTPClient.METHOD_GET, _profile_fetched)

func _profile_fetched(profile_data):
	# todo handle reconnect to existing game
	_profile_data = profile_data
	_profile_id = profile_data["id"]

	_game.level.load_level(load("res://levels/home.tscn"))

	remove_child(_splash_ui)

func connect_to_match(address):
	print("joining match at ", address)
	
	_game.level.unload_level()
	
	multiplayer.connected_to_server.connect(_connected_to_match)

	var address_parts = address.split(":")
	var host = address_parts[0]
	var port = int(address_parts[1])

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err establish conn")
		return

	multiplayer.multiplayer_peer = peer

	print("conn up")

func _connected_to_match():
	_game.match_bind.rpc(multiplayer.get_unique_id(), _profile_id)

	print("conn bound")
