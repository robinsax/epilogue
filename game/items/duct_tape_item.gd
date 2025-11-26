class_name DuctTapeItem extends UseableItem

@export var restore_to: float = 1.0
@export var total_uses: int = 3

@export var uses: int

var _is_using: bool
var _use_sound_time: float

func _ready():
	super._ready()

	if is_multiplayer_authority():
		uses = total_uses

func _process(delta):
	super._process(delta)

	if _is_using:
		_use_sound_time -= delta
		if _use_sound_time <= 0:
			custom_audio.play_clip_rpc(randi_range(0, 2))
			_use_sound_time = 0.7

func _get_next_hitbox(character: Character) -> CharacterHitbox:
	for hitbox in character.hitboxes:
		if not hitbox.is_mechanical:
			continue
		if hitbox.current_hitpoints > 0.0:
			continue

		return hitbox

	return null

func get_detail_string() -> String:
	return str(uses) + "/" + str(total_uses) + " uses"

func can_be_used(character: Character) -> bool:
	return uses > 0 and _get_next_hitbox(character) != null

func animate_biped_use(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float, callback: Callable):
	var end_callback = func ():
		callback.call()
		custom_audio.play_clip_rpc(3)
		_is_using = false

	_is_using = true
	rig.main_hand_ik.reach_to(
		offset_animation_target_forward(character, _get_next_hitbox(character).global_position),
		end_callback, 1.5, true
	)

func authority_use(character: Character):
	var hitbox = _get_next_hitbox(character)
	if hitbox == null or uses <= 0:
		return

	print(hitbox.name, " restore")
	hitbox.inform_heal.rpc(1)
	uses -= 1
