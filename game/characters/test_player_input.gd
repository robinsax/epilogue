extends MultiplayerSynchronizer

var MOUSE_SENS = 0.002

var _character = null

@export var move_direction = Vector2()
@export var rotation = Vector3()
@export var jumping = false

func _ready():
	_character = get_parent()
	set_process(_character.is_local_authority())
	set_process_input(_character.is_local_authority())

func _process(delta):
	# reset all
	move_direction = Input.get_vector("mv_left", "mv_right", "mv_forward", "mv_back")
	rotation = Vector3()
	jumping = false

@rpc("call_local")
func _jump():
	jumping = true

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_jump.rpc()
	
	if event.is_action_pressed("interact"):
		_character.possession.interact()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation = Vector3(-event.relative.y * MOUSE_SENS, -event.relative.x * MOUSE_SENS, 0)
