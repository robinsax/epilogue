class_name CharacterShellInterface extends Object

func get_floor_angle() -> float:
	return 0.0

func is_on_floor() -> bool:
	return false

func get_collision_mask() -> int:
	return 0

func get_rids() -> Array[RID]:
	return []

func physics_update_move(velocity: Vector3, delta: float):
	pass
