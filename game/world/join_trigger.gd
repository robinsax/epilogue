extends Area3D

var API_URI = "http://127.0.0.1"

var state = "none"
var queue_state = "unknown"
var active_req = null
var poll_time = 2.0

func _ready():
	connect("body_entered", _do_trigger)

func _process(delta):
	poll_time -= delta
	if poll_time < 0.0: # todo dont spin unless needed
		poll_time = 2.0
		print(state, " ", queue_state)
		if state != "queued_idle":
			return
		_poll_queue()

func _do_trigger(body):
	var player = body as CharacterBody3D
	if not player:
		return
		
	_queue()

func _make_req(endpoint, method, callback):
	print("req ", endpoint, " ", method)

	active_req = HTTPRequest.new()
	add_child(active_req)

	active_req.request_completed.connect(callback)
	var err = active_req.request(API_URI + endpoint + "?user=godot", [], method)
	if err != OK:
		print("err")

func _parse_resp(res, code, headers, body):
	print("res ", res, " resp ", code)

	if res != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("err")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	remove_child(active_req)
	active_req = null
	
	return data

func _queue():
	if state != "none":
		return
	state = "queuing"
	
	_make_req("/queue", HTTPClient.METHOD_POST, _on_queue_polled)

func _poll_queue():
	if state != "queued_idle":
		return
	state = "queued_polling"
	
	_make_req("/queue", HTTPClient.METHOD_GET, _on_queue_polled)

func _on_queue_polled(res, code, headers, body):
	var data = _parse_resp(res, code, headers, body)
	queue_state = data["state"]
	
	if queue_state == "active":
		state = "joining"
		
		_make_req("/match/" + data["match_id"], HTTPClient.METHOD_GET, _on_match_fetched)
	else:
		state = "queued_idle"

func _on_match_fetched(res, code, headers, body):
	var data = _parse_resp(res, code, headers, body)

	get_node("/root/game").join(data)
