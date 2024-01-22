# todo combine with client_driver

extends Node

var _game = null

var _state = "none"
var _queue_state = "unknown"
var _match_state = "unknown"
var _match_id = null
var _poll_time = 2.0

func _ready():
	_game = get_node("/root/game")

func _process(delta):
	if _state != "queued_idle" and _state != "matched_idle":
		return

	_poll_time -= delta
	if _poll_time < 0.0: # todo dont spin unless needed
		_poll_time = 2.0
		if _queue_state == "matched":
			_poll_match()
		else:
			_poll_queue()

func queue(item_list):
	if _state != "none":
		return
	_state = "queuing"
	
	var data = { "items": item_list }
	
	_game.net.make_req("/queue", HTTPClient.METHOD_POST, _queue_polled, data)

func get_state():
	if _state == "queued_idle" or _state == "queued_polling":
		return "queued"
	if _state == "matched_idle" or _state == "matched_polling":
		return "matched"
	return _state

func _poll_queue():
	if _state != "queued_idle":
		print("warn: dup poll queue")
		return
	_state = "queued_polling"
	
	_game.net.make_req("/queue", HTTPClient.METHOD_GET, _queue_polled)

func _poll_match():
	if _state != "matched_idle":
		print("warn: dup poll match")
		return
	_state = "matched_polling"

	_game.net.make_req("/match/" + _match_id, HTTPClient.METHOD_GET, _match_polled)

func _queue_polled(data):
	_queue_state = data["state"]
	
	if _queue_state == "matched":
		print("matched")
		
		_state = "matched_idle"
		_match_id = data["match_id"]
	else:
		_state = "queued_idle"

func _match_polled(data):
	_match_state = data["state"]
	
	if _match_state == "active":
		print("match ready")
		
		_state = "joining"
		_game.driver.connect_to_match(data["address"])
	else:
		_state = "matched_idle"
