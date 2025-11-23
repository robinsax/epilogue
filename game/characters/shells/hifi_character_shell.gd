class_name HiFiCharacterShell extends CharacterBody3D

var character: Character = null

class Interface extends CharacterShellInterface:
	var _shell: HiFiCharacterShell

	func is_on_floor() -> bool:
		return _shell.is_on_floor()

	func get_floor_angle() -> float:
		return _shell.get_floor_angle()

	func get_collision_mask() -> int:
		return _shell.collision_mask

	func get_rids() -> Array[RID]:
		return [_shell.get_rid()]

	func physics_update_move(velocity: Vector3, delta: float):
		_shell.velocity = velocity
		_shell.move_and_slide()

func _ready():
	character = $Character

	character.remove_child(character.collider)
	add_child(character.collider)

	_possess_if_owned()

func _possess_if_owned():
	var name_id = int(name)
	var authority = name_id
	# TODO: No.
	if name_id == 0 or (name_id > 1 and name_id < 1000):
		authority = 1
	set_multiplayer_authority(authority)
	if name_id == authority:
		var possession = load("res://meta/player_possession.tscn").instantiate()
		character.add_child(possession, true)

func get_interface() -> CharacterShellInterface:
	var instance = Interface.new()
	instance._shell = self

	return instance
