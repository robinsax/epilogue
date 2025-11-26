class_name CharacterHitbox extends Area3D

@export var hitpoints: int = 10
@export var is_cripple_lethal: bool = false
@export var damage_effect: Resource = null
@export var group_with: CharacterHitbox = null
@export var label: String = "Body Part"
@export var is_headshot: bool = false
@export var is_mechanical: bool = false

@export var current_hitpoints: float = 0

var group_members: Array[CharacterHitbox]

var character: Character
var _damage_effect_instance: Node3D

func _ready():
	current_hitpoints = hitpoints

	var current = get_parent()
	while not current is Character:
		current = current.get_parent()
	character = current

	if group_with != null:
		group_with.group_members.push_back(self)
	else:
		character.hitboxes.push_back(self)

func _process(delta):
	if character.update_culled:
		return

	# TODO: Lol.
	set_multiplayer_authority(1)

	if current_hitpoints < hitpoints / 2.0:
		if _damage_effect_instance == null:
			_damage_effect_instance = damage_effect.instantiate()
			var parent_scale = global_basis.get_scale()
			add_child(_damage_effect_instance)
			_damage_effect_instance.global_basis = Basis.from_scale(Vector3(
				1.0 / parent_scale.x,
				1.0 / parent_scale.y,
				1.0 / parent_scale.z
			))
	elif _damage_effect_instance != null:
		remove_child(_damage_effect_instance)
		_damage_effect_instance = null

func take_kinetic_damage(amount: float):
	if group_with != null:
		group_with.take_kinetic_damage(amount)
		return

	print(get_parent().name, " ", amount, " ", current_hitpoints)
	var takeable = min(current_hitpoints, amount)
	var remainder = amount - takeable
	current_hitpoints -= takeable

	if remainder > 0:
		character.distribute_overflow_kinetic_damage(remainder)

@rpc("any_peer", "call_local")
func inform_damage(kinetic_amount: float):
	# TODO: Manager damage externally for authority.
	if not is_multiplayer_authority():
		return

	take_kinetic_damage(kinetic_amount)

@rpc("any_peer", "call_local")
func inform_heal(kinetic_amount: float):
	if not is_multiplayer_authority():
		return

	current_hitpoints = min(hitpoints, current_hitpoints + kinetic_amount)
