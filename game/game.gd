extends Node3D

var net = null
var factory = null
var level = null
var connector = null # todo combine with driver

var driver = null

func _ready():
	net = $net
	factory = $factory
	level = $level
	connector = $connector

	if DisplayServer.get_name() == "headless":
		_server_init()
	else:
		_client_init()

func _server_init():
	print("server init")
	net.use_hub_api()

	driver = load("res://meta/server_driver.tscn").instantiate()
	add_child(driver)
	driver.initialize()

func _client_init():
	print("client init")
	net.use_client_api()

	driver = load("res://meta/client_driver.tscn").instantiate()
	add_child(driver)
	driver.initialize()

@rpc("any_peer")
func match_bind_player(conn_id, profile_id):
	if not multiplayer.is_server():
		return

	driver.bind_player(conn_id, profile_id)

@rpc("authority", "call_remote")
func match_exfil_player(profile_id):
	if profile_id != driver.profile_id():
		return
	
	print("client exfil")
	driver.disconnect_from_match()
