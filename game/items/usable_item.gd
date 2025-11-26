class_name UseableItem extends Item

func wants_animate_biped(character: RobotBipedCharacter) -> bool:
	return (
		character.can_perform_actions() and
		not character.aiming and character.firing and can_be_used(character)
	)

func animate_biped_as_active(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float):
	var on_complete = func ():
		_inform_use.rpc(character.shell.get_name())
	animate_biped_use(character, rig, delta, on_complete)

func offset_animation_target_forward(character: Character, target: Vector3) -> Vector3:
	return target + (Vector3.FORWARD * 0.1).rotated(Vector3.UP, character.global_rotation.y)

func animate_biped_use(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float, callback: Callable):
	pass

@rpc("any_peer", "call_local")
func _inform_use(target_character: String):
	if not is_multiplayer_authority():
		return

	authority_use(World.current.get_character(target_character))

func can_be_used(character: Character) -> bool:
	return false

func authority_use(character: Character):
	pass
