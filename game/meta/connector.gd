# todo combine with client_driver

extends Node

var _game = null

var state = "none"
var queue_state = "unknown"
var match_state = "unknown"
var match_id = null
var poll_time = 2.0

func _ready():
	_game = get_node("/root/game")

func _process(delta):
	if state != "queued_idle" and state != "matched_idle":
		return

	poll_time -= delta
	if poll_time < 0.0: # todo dont spin unless needed
		poll_time = 2.0
		if queue_state == "active":
			_poll_match()
		else:
			_poll_queue()

func queue(item_list):
	if state != "none":
		return
	state = "queuing"
	
	var data = { "items": item_list }
	
	_game.net.make_req("/queue", HTTPClient.METHOD_POST, _queue_polled, data)

func get_state():
	if state == "queued_idle" or state == "queued_polling":
		return "queued"
	if state == "matched_idle" or state == "matched_polling":
		return "matched"
	return state

func _poll_queue():
	if state != "queued_idle":
		print("warn: dup poll queue")
		return
	state = "queued_polling"
	
	_game.net.make_req("/queue", HTTPClient.METHOD_GET, _queue_polled)

func _poll_match():
	if state != "matched_idle":
		print("warn: dup poll match")
		return
	state = "matched_polling"

	_game.net.make_req("/match/" + match_id, HTTPClient.METHOD_GET, _match_polled)

func _queue_polled(data):
	queue_state = data["state"]
	
	if queue_state == "active":
		print("matched")
		
		state = "matched_idle"
		match_id = data["match_id"]
	else:
		state = "queued_idle"

func _match_polled(data):
	match_state = data["state"]
	
	if match_state == "active":
		print("match ready")
		
		state = "joining"
		_game.driver.connect_to_match(data["address"])
	else:
		state = "matched_idle"
