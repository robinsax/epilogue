class_name BatteryItem extends UseableItem

@export var charged: bool = true

func can_be_used(character: Character) -> bool:
	return character.charge_port != null and charged

func animate_biped_use(character: RobotBipedCharacter, rig: RobotBipedRig, delta: float, callback: Callable):
	custom_audio.play_clip_rpc(0)
	rig.main_hand_ik.reach_to(character.charge_port.global_position, callback, 2.0)

func authority_use(character: Character):
	charged = false
	character.update_energy.rpc(150.0)

func get_detail_string() -> String:
	if charged:
		return "Charged"
	else:
		return "Expended"
