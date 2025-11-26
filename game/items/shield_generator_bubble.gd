class_name ShieldGeneratorBubble extends Area3D

var _sounds: AudioStreamPlayer3D

func _ready() -> void:
	_sounds = $Sounds

	area_entered.connect(_handle_area_enter)
	body_entered.connect(_handle_body_enter)
	body_exited.connect(_handle_body_exit)
	_sounds.play()

func _handle_body_enter(node: Node3D):
	if node is HiFiCharacterShell and node.character == PlayerPossession.current.character:
		AudioServer.add_bus_effect(0, AudioEffectLowPassFilter.new())

func _handle_body_exit(node: Node3D):
	if node is HiFiCharacterShell and node.character == PlayerPossession.current.character:
		AudioServer.remove_bus_effect(0, 0)

func _handle_area_enter(node: Node3D):
	if not node is Projectile:
		return

	node.global_basis = node.global_basis.transposed()
