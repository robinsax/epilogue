extends Node3D

var _game = null
var _splash_ui = null

var _is_direct_conn = false

var _profile_id = null
var _profile_data = null # missing if direct connect

func profile_id():
	return _profile_id

func profile_data():
	return _profile_data

func initialize():
	_game = get_node("/root/game")

	var direct_conn_addr = OS.get_environment("DIRECT_CONNECT")
	# todo no
	if direct_conn_addr == "" and "--dcon" in OS.get_cmdline_user_args():
		direct_conn_addr = "127.0.0.1:5000"
	_is_direct_conn = direct_conn_addr != ""
	if _is_direct_conn:
		_profile_id = "foo"
		if OS.has_environment("PROFILE_ID"):
			_profile_id = OS.get_environment("PROFILE_ID")

		remove_child(_splash_ui)

		connect_to_match(direct_conn_addr)
	else:
		_fetch_profile_for_home()

func _fetch_profile_for_home():
	_splash_ui = load("res://ui/splash.tscn").instantiate()
	add_child(_splash_ui)

	_game.net.make_req("/profile", HTTPClient.METHOD_GET, _profile_fetched_for_home)

func _profile_fetched_for_home(profile_data):
	_profile_data = profile_data
	_profile_id = profile_data["id"]
	
	var active_match = profile_data["active_match"]
	if active_match != null:
		_game.net.make_req("/match/" + active_match, HTTPClient.METHOD_GET, _reconnect_to_match)
		return

	_game.level.load_level(load("res://levels/home.tscn").instantiate())

	remove_child(_splash_ui)

func _reconnect_to_match(match_data):
	remove_child(_splash_ui)

	connect_to_match(match_data["address"])

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

func disconnect_from_match():
	if _is_direct_conn:
		print("direct conn, quitting on dc")
		get_tree().quit()
		return

	multiplayer.connected_to_server.disconnect(_connected_to_match)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_node("/root/game/connector")._state = "none" # todo lol
	
	print("disconnected")
	
	_fetch_profile_for_home()

func _connected_to_match():
	_game.match_bind_player.rpc(multiplayer.get_unique_id(), _profile_id)

	print("conn bound")
