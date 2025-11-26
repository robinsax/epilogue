class_name WrenchItem extends UseableItem

@export var heal_limit: float = 0.75

var _is_using: bool
var _use_sound_time: float

func _process(delta):
	super._process(delta)

	if _is_using:
		_use_sound_time -= delta
		if _use_sound_time <= 0:
			custom_audio.play_clip_rpc(0)
			_use_sound_time = 0.7

func _get_next_hitbox(character: Character) -> CharacterHitbox:
	var best: CharacterHitbox = null
	var best_value: float = 0.0
	for hitbox in character.hitboxes:
		var hitbox_limit = hitbox.hitpoints * heal_limit
		if not hitbox.is_mechanical:
			continue
		if hitbox.current_hitpoints > hitbox_limit:
			continue
		if hitbox.current_hitpoints <= 0.0:
			continue

		var value = hitbox_limit - hitbox.current_hitpoints
		if value <= 0.0:
			continue

		if best == null or best_value < value:
			best = hitbox
			best_value = value

	return best

func can_be_used(character: Character) -> bool:
	return _get_next_hitbox(character) != null

func animate_biped_use(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float, callback: Callable):
	var end_callback = func ():
		callback.call()
		_is_using = false

	_is_using = true
	rig.main_hand_ik.reach_to(
		offset_animation_target_forward(character, _get_next_hitbox(character).global_position),
		end_callback, 1.5, true
	)

func authority_use(character: Character):
	var hitbox = _get_next_hitbox(character)
	if hitbox == null:
		return

	var heal_amount = min(10.0, (hitbox.hitpoints * heal_limit) - hitbox.current_hitpoints)
	print(hitbox.name, " ", hitbox.hitpoints, " -> ", heal_amount)
	hitbox.inform_heal.rpc(heal_amount)
