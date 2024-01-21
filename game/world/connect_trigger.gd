extends StaticBody3D

# todo signals

var _connector = null
var _home_level = null

func _ready():
	_connector = get_node("/root/game/connector")
	_home_level = get_node("/root/game/level/level_root")

func interact_info():
	return 'drop in'
	
func interact(character):
	_home_level.queue()

func _process(delta):
	$text.text = _connector.get_state()
