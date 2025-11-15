extends Node3D

var MAX_CLIENTS = 8

var _game = null

var _is_standalone = null
var _match_id = null # missing if standalone
var _match_data = null
var _profile_ids = {}
var _exfiled = []

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
		
		print("standalone match data ", _match_data)
		
		_prepare_level()
		return

	_match_id = OS.get_environment("MATCH_ID")
	_game.net.make_req("/match/" + _match_id, HTTPClient.METHOD_GET, _finalize_initialize)

func _finalize_initialize(match_data):
	_match_data = match_data
	
	_prepare_level()

func _prepare_level():
	# have to open the server first or replicators break....
	var port = int(OS.get_environment("PORT"))

	multiplayer.peer_connected.connect(_client_connected)
	multiplayer.peer_disconnected.connect(_client_disconnected)

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_CLIENTS)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("err boot multiplayer server")
		return

	multiplayer.multiplayer_peer = peer

	var level = load("res://levels/match.tscn").instantiate()
	level.generated.connect(_level_prepared)
	_game.level.load_level(level)

func _level_prepared():
	if _is_standalone:
		return

	_game.net.make_req(
		"/match/" + _match_id,
		HTTPClient.METHOD_POST,
		_match_reported_started,
		{ 'state': 'active' }
	)

func bind_player(conn_id, profile_id): # rpc needs to exist on /game
	# todo authz somehow

	if profile_id not in _match_data["profiles"]:
		print('err conn bind: no profile')
		return

	if conn_id in _profile_ids:
		print('err conn bind: rebind')
		return
	
	if profile_id in _profile_ids.values():
		print('err conn: double bind profile')
		return
	
	print("bind ", conn_id, " to profile ", profile_id)
	_profile_ids[conn_id] = profile_id

	var player = _game.level.players.get_node(profile_id) # find existing
	if player != null:
		print("rebinding to existing")
	else:
		player = _game.factory.spawn_player(Vector3(10 * randf(), 0, 10 * randf()), profile_id)

		var owned_items = []
		for item in _match_data["items"]:
			if item["attachment"][0] == profile_id:
				owned_items.append(item)

		_game.factory.spawn_items(owned_items, player)

		print("spawned, with ", len(owned_items), " items")

	player.conn_id = conn_id

func exfil_player(player):
	var profile_id = player.name
	print("exfil ", profile_id)
	
	var player_result = player.data()
	if _is_standalone:
		print("standalone, exfil ", profile_id, " with result ", player_result)
		_game.match_exfil_player.rpc(profile_id)
		return
	
	_game.net.make_req(
		"/match/" + _match_id + "/player-results/" + profile_id,
		HTTPClient.METHOD_POST,
		_player_exfiled,
		player_result
	)

func _player_exfiled(data):
	var profile_id = data["profile_id"]
	var player = _game.level.player_for(profile_id)

	for item in player.inventory.items():
		item.queue_free()
	player.queue_free()

	print("exfil ", profile_id, " confirmed")
	_game.match_exfil_player.rpc(profile_id)
	_exfiled.append(profile_id)

func _client_connected(conn_id):
	print("conn ", conn_id)

func _client_disconnected(conn_id):
	print(conn_id, " dropped")

	if conn_id not in _profile_ids:
		print("...was unbound")
		return

	var profile_id = _profile_ids[conn_id]
	if profile_id not in _exfiled:
		# save player for later
		var player = _game.level.players.get_node(profile_id)
		player.conn_id = 1
	_profile_ids.erase(conn_id)
	
	if len(_exfiled) != len(_match_data["profiles"].keys()):
		return
	print("all players exfiled")

	if _is_standalone:
		print("standalone match, exiting")
		get_tree().quit()
		return

	_game.net.make_req(
		"/match/" + _match_id,
		HTTPClient.METHOD_POST,
		_match_reported_ended,
		{ 'state': 'ended' }
	)

func _match_reported_started(data):
	print("reported start")

func _match_reported_ended():
	print("reported ended")
