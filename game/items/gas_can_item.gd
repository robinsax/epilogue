class_name GasCanItem extends Item

@export var fuel_capacity: float = 6.0

@export var fuel_remaining: float = 0.0

var _filling: GeneratorObject
var _fill_time: float
var _fill_sound: AudioStreamPlayer3D

func _ready():
	super._ready()

	_fill_sound = $FillSound

	fuel_remaining = fuel_capacity

func _process(delta):
	super._process(delta)

	if _filling != null:
		_fill_time += delta
		if not _fill_sound.playing:
			_fill_sound.play()
		if _fill_time > 1.0:
			_do_fill.rpc(World.current.get_static_object_ref(_filling))
			_fill_time = 0.0
	else:
		_fill_time = 0.0
		_fill_sound.stop()
	_filling = null

func get_detail_string() -> String:
	return str(int(fuel_remaining)) + "/" + str(int(fuel_capacity)) + "L"

func wants_animate_biped(character: RobotBipedCharacter) -> bool:
	return (
		character.object_interact_target != null and character.firing and not character.aiming and
		"takesfuel" in character.object_interact_target.tags and fuel_remaining > 0.0
	)

func animate_biped_as_active(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	rig.main_hand_ik.root_global_position = character.object_interact_target.global_position
	_filling = character.object_interact_target.get_parent()

@rpc("any_peer", "call_local")
func _do_fill(gen_ref: String):
	if not is_multiplayer_authority():
		return

	var generator: GeneratorObject = World.current.get_static_object(gen_ref)
	var amount = min(1.0, fuel_remaining)
	generator.fuel_remaining += amount
	fuel_remaining -= amount
