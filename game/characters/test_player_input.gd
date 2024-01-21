extends MultiplayerSynchronizer

@export var move_direction = Vector2()
@export var rotation = Vector3()
@export var jumping = false
@export var interacting = false

var mouse_sensitivity = 0.002

func _ready():
	var is_authority = get_multiplayer_authority() == multiplayer.get_unique_id()
	set_process(is_authority)
	set_process_input(is_authority)

func _process(delta):
	move_direction = Input.get_vector("mv_left", "mv_right", "mv_forward", "mv_back")
	rotation = Vector3()
	jumping = false
	interacting = false

@rpc("call_local")
func jump():
	jumping = true
	
@rpc("call_local")
func interact():
	interacting = true

func _input(event):
	if event.is_action_pressed("ui_accept"):
		jump.rpc()
	
	if event.is_action_pressed("interact"):
		interact.rpc()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation = Vector3(-event.relative.y * mouse_sensitivity, -event.relative.x * mouse_sensitivity, 0)
