extends Node3D

var MAX_CLIENTS = 8

var _game = null

var _is_standalone = null
var _match_id = null # missing if standalone
var _match_data = null
var _profile_ids = {}

func match_data():
	return _match_data

func profile(profile_id):
	return _match_data["profiles"][profile_id]

func conn_profile(conn_id):
	return profile(_profile_ids[conn_id])

func initialize():
	_game = get_node("/root/game")

	_is_standalone = OS.has_environment("STANDALONE")
	if _is_standalone:
		var file = FileAccess.open(OS.get_environment("MATCH_DATA_PATH"), FileAccess.READ)
		_match_data = JSON.parse_string(file.get_as_text())
		
		_open_server()
		return

	_match_id = OS.get_environment("MATCH_ID")
	_game.net.make_req("/match/" + _match_id, HTTPClient.METHOD_GET, _finalize_initialize)
	
func _finalize_initialize(match_data):
	_match_data = match_data
	
	_open_server()

func _open_server():
	var port = int(OS.get_environment("PORT"))

	_game.multiplayer.peer_connected.connect(_client_connected)
	_game.multiplayer.peer_disconnected.connect(_client_disconnected)

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_CLIENTS)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err boot multiplayer server")
		return

	_game.multiplayer.multiplayer_peer = peer

	_game.level.load_level(load("res://levels/match.tscn"))
	
	if not _is_standalone:
		_game.net.make_req("/match/" + _match_id, HTTPClient.METHOD_POST, _match_reported_started, { 'state': 'active' })

func bind_player(conn_id, profile_id): # rpc needs to exist on /game
	# todo authz somehow

	if conn_id in _profile_ids:
		print('err conn bind: rebind')
		return
	
	if not profile_id in _match_data["profiles"]:
		print('err conn bind: no profile')
		return

	print("bind ", conn_id, " to profile ", profile_id)
	_profile_ids[conn_id] = profile_id
	
	var player = _game.factory.spawn_player(Vector3(10 * randf(), 0, 10 * randf()), profile_id, conn_id)

	var owned_items = []
	for item in _match_data["items"]:
		if item["attachment"][0] == profile_id:
			owned_items.append(item)

	_game.factory.spawn_items(owned_items, player)

	print("spawned, with ", len(owned_items), " items")

func _match_reported_started(data):
	print("reported start")

func _client_connected(conn_id):
	print("conn ", conn_id)

func _client_disconnected(conn_id):
	print(conn_id, " dropped")

	var character_id = _profile_ids[conn_id]
	_profile_ids.erase(conn_id)

	if not _game.level.players.has_node(character_id):
		return
	_game.level.players.get_node(character_id).queue_free()
