extends Area3D

var _game = null

func _ready():
	_game = get_node("/root/game")

	body_entered.connect(_collision)

func _collision(body):
	if not multiplayer.is_server():
		return

	_game.driver.exfil_player(body)
