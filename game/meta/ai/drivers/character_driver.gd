class_name CharacterDriver extends Object

var _character: Character = null
var _possession: AIPossession = null

static func get_for_character(character: Character) -> CharacterDriver:
	if character is GroundCharacter:
		return GroundCharacterDriver.new()
	return CharacterDriver.new()

func bind(character: Character, possession: AIPossession):
	_character = character
	_possession = possession

func reset_update():
	_character.move_direction = Vector3.ZERO
	_character.firing = false
	_character.aiming = false

func cosmetic_update(state: AIState):
	if state.fixation != null:
		_character.look_target = state.fixation.global_position
	else:
		_character.look_target = _character.to_global(Vector3.FORWARD)

func sneak():
	pass

func move_towards(global_position: Vector3):
	pass

func look_towards(global_position: Vector3):
	pass
