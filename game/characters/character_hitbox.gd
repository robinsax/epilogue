class_name CharacterHitbox extends Area3D

@export var hitpoints: int = 10
@export var is_cripple_lethal: bool = false

@export var current_hitpoints: int = 0

var _character: Character = null

func _ready():
	current_hitpoints = hitpoints

	var current = get_parent()
	while not current is Character:
		current = current.get_parent()
	_character = current
	_character.hitboxes.push_back(self)

	area_entered.connect(_damage_collision)

func _process(delta):
	# TODO: Lol.
	set_multiplayer_authority(1)

func _damage_collision(source: Node3D):
	if not source is Projectile:
		return

	if is_multiplayer_authority():
		take_kinetic_damage(source.kinetic_damage)

func take_kinetic_damage(amount: float):
	print(get_parent().name, " ", amount, " ", current_hitpoints)
	var takeable = min(current_hitpoints, amount)
	var remainder = amount - takeable
	current_hitpoints -= takeable

	if remainder > 0:
		_character.distribute_overflow_kinetic_damage(remainder)
