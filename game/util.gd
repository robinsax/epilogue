extends Node

var API_URI = "http://127.0.0.1"

var client_name = null
var active_req = null
var active_callback: Callable = _noop
var host_node = null

func _noop(data):
	pass

func bind(node):
	client_name = "from-engine"
	if OS.has_environment("CLIENT_NAME"):
		client_name = OS.get_environment("CLIENT_NAME")
	
	host_node = node

func make_req(endpoint, method, callback):
	var url = API_URI + endpoint
	print("req ", url, " ", method)
	
	active_callback = callback

	active_req = HTTPRequest.new() # avoid host_node with httpserver?
	host_node.add_child(active_req)

	active_req.request_completed.connect(_handle_resp)
	var err = active_req.request(url + "?user=" + client_name, [], method)
	if err != OK:
		print("err opening request")

func _handle_resp(res, code, headers, body):
	print("res ", res, " resp ", code)

	if res != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("err result or response")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	active_callback.call(data)

	host_node.remove_child(active_req)
	active_req = null
	active_callback = _noop