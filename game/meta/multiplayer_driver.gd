class_name MultiplayerDriver extends Node

@export var _world_resource: Resource = null

var _game: Node3D = null
var _world: World = null
var _is_server: bool = false

func _ready():
	_game = get_parent()

	var connect_to = OS.get_environment("CONNECT_TO")
	_is_server = connect_to.length() == 0
	if _is_server:
		_init_as_server()
	else:
		_init_as_client(connect_to)

func _spawn_world():
	_world = _world_resource.instantiate()
	_world.prepared.connect(_server_on_world_prepared)
	_game.get_node("WorldContainer").add_child(_world, true)
	print("World spawned")

func _init_as_server():
	var port = 6000
	var port_value = OS.get_environment("SERVER_PORT")
	if port_value.length() > 0:
		port = int(port_value)

	multiplayer.peer_connected.connect(_server_on_client_connect)
	multiplayer.peer_disconnected.connect(_server_on_client_disconnect)

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to launch server")
		return

	multiplayer.multiplayer_peer = peer
	print("Server bound")

	_spawn_world()

func _server_on_world_prepared():
	print("World prepared")

	var standalone = OS.get_environment("STANDALONE").length() > 0
	if not standalone:
		_spawn_character(multiplayer.get_unique_id())

func _server_on_client_connect(conn_id: int):
	print("Client ", conn_id, " connected")

func _server_on_client_disconnect(conn_id: int):
	print("Client ", conn_id, " disconnected")

func _init_as_client(server_address: String):
	multiplayer.connected_to_server.connect(_client_on_connected)

	var address_parts = server_address.split(":")
	var host = address_parts[0]
	var port = int(address_parts[1])

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Error connecting to server")
		return

	multiplayer.multiplayer_peer = peer
	print("Connected to server")

func _client_on_connected():
	print("Client connected")

	_spawn_world()
	_spawn_character.rpc(multiplayer.get_unique_id())

@rpc("any_peer")
func _spawn_character(conn_id: int):
	if not multiplayer.is_server():
		return

	var character = load("res://characters/shells/test_player_shell.tscn").instantiate()
	character.name = str(conn_id)
	_world.characters.add_child(character, true)
	character.global_position = _world.get_node("Static/Spawns").global_position
	print("Spawned character ", character, " for ", conn_id)
