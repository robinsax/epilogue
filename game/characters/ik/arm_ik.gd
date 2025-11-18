class_name ArmIK extends SkeletonIK3D

@export var reach_speed: float = 0.3

@export var slot: InventorySlot = null

var _character: Character = null

var _target: Node3D = null
var root_global_position: Vector3 = Vector3.ZERO

var _reaching: bool = false
var _reach_target: Vector3 = Vector3.ZERO
var _reach_time: float = 0
var _reach_callback: Callable = Callable()

var _lock_target: Node3D = null

func _ready():
	_target = $Target
	_character = Character.find_parent_character(self)

	start()

func _process(delta):
	if _character.dead:
		stop()
		return

	if _lock_target:
		_target.global_position = _lock_target.global_position
	elif not root_global_position.is_zero_approx():
		_target.global_position = root_global_position
	else:
		_target.position = Vector3.ZERO

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

	_target.position = _reach_target

func is_busy():
	return _lock_target != null or _reach_time > 0.0

func reach_to(reach_target: Vector3, then: Callable):
	_reach_callback = then

	_play_reach_anim.rpc(reach_target)

func lock_to(lock_target: Node3D):
	_lock_target = lock_target

@rpc("any_peer", "call_local")
func _play_reach_anim(reach_target: Vector3):
	_reach_target = to_local(reach_target)
	_reaching = true
