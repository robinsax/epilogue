class_name GroundCharacterDriver extends CharacterDriver

var _target: GroundCharacter = null

func bind(character: Character, possession: AIPossession):
	super.bind(character, possession)

	_target = character

func reset_update():
	super.reset_update()

	_target.crouching = false

func move_towards(global_position: Vector3):
	var direction = global_position - _target.global_position
	direction.y = 0.0
	_target.look_at(global_position)
	_target.global_rotation.z = 0.0
	_target.global_rotation.x = 0.0

	_target.move_direction = Vector3.FORWARD

func look_towards(global_position: Vector3):
	_target.look_at(global_position)
	_target.global_rotation.x = 0
	_target.global_rotation.z = 0

func sneak():
	_target.crouching = true
