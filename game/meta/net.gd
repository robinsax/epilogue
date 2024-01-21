extends Node

var CLIENT_API_URI = "http://127.0.0.1"

var client_name = null

var _active_req = null
var _active_callback: Callable = _noop
var _using_hub_api = false
var _api_root = null

func _noop(data):
	pass

func _ready():
	client_name = "from-engine"
	if OS.has_environment("CLIENT_NAME"):
		client_name = OS.get_environment("CLIENT_NAME")

func use_hub_api():
	_using_hub_api = true
	_api_root = OS.get_environment("HUB_API_URI")

func use_client_api():
	_using_hub_api = false
	_api_root = CLIENT_API_URI

func make_req(endpoint, method, callback, body=null):
	var url = _api_root + endpoint
	print("req ", url, " ", method)
	
	_active_callback = callback

	_active_req = HTTPRequest.new() # avoid host_node with httpserver?
	add_child(_active_req)
	
	var headers = []
	var body_str = ""
	if body != null:
		headers.append("Content-Type: application/json")
		body_str = JSON.stringify(body)

		print(headers, " ", body_str)
		
	if not _using_hub_api:
		url += "?user=" + client_name

	_active_req.request_completed.connect(_handle_resp)
	var err = _active_req.request(url, headers, method, body_str)
	if err != OK:
		print("err opening request")

func _handle_resp(res, code, headers, body):
	print("res ", res, " resp ", code)

	if res != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("err result or response")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	var callback = _active_callback

	remove_child(_active_req)
	_active_req = null
	_active_callback = _noop

	callback.call(data)
