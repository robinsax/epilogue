extends StaticBody3D

var connector = null

func _ready():
	connector = get_node("/root/game/connector")

func get_character_interact_info():
	return 'drop in'
	
func character_interact(character):
	connector.queue()

func _process(delta):
	$text.text = connector.get_state()
