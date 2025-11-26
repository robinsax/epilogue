class_name MagazineItem extends Item

@export var capacity: int = 20
@export var projectile_type: Resource = null

@export var _remaining: int = 0

func _ready():
	super._ready()

	_remaining = capacity

func get_remaining_projectiles():
	return _remaining

func get_detail_string() -> String:
	return str(get_remaining_projectiles()) + "/" + str(capacity)

func pop_next_projectile_type() -> Resource:
	if _remaining <= 0:
		return null

	_remaining -= 1
	return projectile_type
