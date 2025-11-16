class_name ArmIK extends SkeletonIK3D

@export var reach_speed: float = 0.3

var _target: Node3D = null

var _reaching: bool = false
var _reach_target: Vector3 = Vector3.ZERO
var _reach_time: float = 0
var _reach_callback: Callable = Callable()

func _ready():
	_target = $Target

	start()

func _process(delta):
	_update_reaching(delta)

func _update_reaching(delta):
	if not _reaching:
		return

	_reach_time += delta
	if _reach_time >= reach_speed:
		_target.position = Vector3.ZERO
		_reach_time = 0
		_reach_target = Vector3.ZERO
		_reaching = false

		if not _reach_callback.is_null():
			_reach_callback.call()

		return

	_target.global_position = _reach_target

func reach_to(reach_target: Vector3, then: Callable):
	_reach_callback = then

	_play_reach_anim.rpc(reach_target)

@rpc("any_peer", "call_local")
func _play_reach_anim(reach_target: Vector3):
	_reach_target = reach_target
	_reaching = true
