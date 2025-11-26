class_name BulletProjectile extends Projectile

@export var ricochet_amount: float = 1.0

func handle_hit(hit: Node3D):
	super.handle_hit(hit)

	if not hit is CharacterHitbox:
		World.current.remove_projectile(self)
