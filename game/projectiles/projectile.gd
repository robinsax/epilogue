class_name Projectile extends Area3D

@export var kinetic_damage: float = 10.0
@export var speed: float = 40.0

var is_cosmetic: bool = false

func _process(delta):
	global_position += global_basis * (Vector3.LEFT * speed * delta)
