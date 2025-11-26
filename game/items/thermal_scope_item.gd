class_name ThermalScopeItem extends Item

var _shader_set: bool

func _process(delta: float) -> void:
	super._process(delta)

	var active = (
		current_slot != null and current_slot.required_tag == "robotheadaug" and
		current_slot.inventory.get_parent().energy > 0.0 and
		current_slot.inventory.get_parent().look_zoomed
	)
	var apply_effect = (
		current_slot != null and
		PlayerPossession.current != null and
		PlayerPossession.current.character == current_slot.inventory.get_parent()
	)
	if apply_effect:
		if active:
			if not _shader_set:
				RenderingServer.global_shader_parameter_set("view_modifier", 1)
				_shader_set = true
		else:
			if _shader_set:
				RenderingServer.global_shader_parameter_set("view_modifier", 0)
				_shader_set = false
