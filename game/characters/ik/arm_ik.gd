class_name ArmIK extends SkeletonIK3D

@export var reach_speed: float = 0.3
@export var cripple_reach_speed_slowdown: float = 3.0

@export var slot: InventorySlot = null
@export var cripple_hitbox: CharacterHitbox = null

var _character: Character

var _target: Node3D
var root_global_position: Vector3

var _reach_target: Vector3
var _reach_time: float
var _reach_callback: Callable
var _reach_fiddle: bool

var _lock_target: Node3D

func _ready():
	_target = $Target
	_character = Character.find_parent_character(self)

func _physics_process(delta):
	if _character.update_culled:
		stop()
		return
	start()

	Stats.stats["ik/active"] += 1

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
	if _reach_time <= 0.0:
		return

	_reach_time -= delta
	if _reach_time <= 0.0:
		_target.position = Vector3.ZERO
		_reach_time = 0
		_reach_target = Vector3.ZERO

		if not _reach_callback.is_null():
			_reach_callback.call()

		return

	_target.position = _reach_target
	if _reach_fiddle:
		_target.position += Vector3(sin(_reach_time * 8.0), 0.0, cos(_reach_time * 10.0)) * 0.5

func is_busy():
	return _lock_target != null or _reach_time > 0.0

func reach_to(reach_target: Vector3, then: Callable, time: float = 0.0, fiddle: bool = false):
	if time < 0.1:
		time = reach_speed
	_reach_callback = then

	_play_reach_anim.rpc(reach_target, time, fiddle)

func lock_to(lock_target: Node3D):
	_lock_target = lock_target

@rpc("any_peer", "call_local")
func _play_reach_anim(reach_target: Vector3, time: float, fiddle: bool):
	_reach_target = to_local(reach_target)
	_reach_time = time
	if cripple_hitbox != null and cripple_hitbox.current_hitpoints <= 0.0:
		_reach_time *= cripple_reach_speed_slowdown

	_reach_fiddle = fiddle
