class_name ImmediateProjectile extends Projectile

@export var no_headshots: bool

var audio: ClippedAudioPlayer

var _ticked: bool

func _ready() -> void:
	super._ready()

	audio = $ClippedAudioPlayer

	Stats.stats["proj/i"] = Stats.stats.get("proj/i", 0) + 1

func _process(delta: float):
	super._process(delta)

	if _ticked:
		Stats.stats["proj/i"] -= 1
		World.current.remove_projectile(self)
	_ticked = true

func handle_hit(hit: Node3D):
	if not hit is CharacterHitbox:
		return

	if hit.is_headshot and no_headshots:
		return

	super.handle_hit(hit)
