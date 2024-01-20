extends Area3D

var connector = null

func _ready():
	connector = get_node("/root/game/connector")
	
	connect("body_entered", _do_trigger)

func _do_trigger(body):
	var player = body as CharacterBody3D
	if not player:
		return
		
	connector.queue()

func _process(delta):
	$text.text = connector.get_state()
