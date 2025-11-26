class_name Projectile extends Area3D

@export var kinetic_damage: float = 10.0
@export var speed: float = 40.0
@export var lifespan: float = 4.0

var is_cosmetic: bool
var _hits: Array[Character]
var _life_time: float

func _ready() -> void:
	_life_time = 0.0

	area_entered.connect(handle_hit)

func _process(delta: float) -> void:
	_life_time += delta
	if _life_time > lifespan:
		World.current.remove_projectile(self)

func _physics_process(delta):
	global_position += global_basis * (Vector3.LEFT * speed * delta)

func handle_hit(hit: Node3D):
	if hit is CharacterHitbox:
		if _hits.find(hit.character) == -1:
			if not is_cosmetic:
				hit.inform_damage.rpc(kinetic_damage)

			_hits.push_back(hit.character)
			hit.character.do_hit_cosmetics(self)
