class_name BugCharacter extends Character

@export var y_speed: float = 1.0

@export var flying: bool = false

var _hit_sounds: ClippedAudioPlayer
var _fly_sound: AudioStreamPlayer3D
var _clip_sounds: ClippedAudioPlayer
var _footstep_time: float
var _rig_base_position: Vector3

var _current_attack_target: Character
var _current_waypoint: Vector3
var _waypoint_time: float
var _spawn_position: Vector3
var _y_move: float
var _last_ground_y: float
var _desired_float: float
var _bite_time: float

func _ready():
	super._ready()

	perception_volumes.push_back($PerceptionVolume)
	flying = true

	_rig_base_position = rig.position
	_spawn_position = global_position
	_desired_float = 2.0

	_hit_sounds = $HitSounds
	_fly_sound = $FlySound
	_clip_sounds = $Clips
	_current_waypoint = _next_waypoint()

func _physics_process(delta):
	super._physics_process(delta)

	if not is_multiplayer_authority():
		return

	_y_move = 0.0
	if not flying and not shell.is_on_floor():
		shell.physics_update_move(Vector3(0.0, -1.0, 0.0), delta)
	elif flying:
		var cast = PhysicsRayQueryParameters3D.create(
			global_position, global_position + (Vector3.DOWN * 20.0),
			CollisionLayers.FAST_GROUND, shell.get_rids()
		)
		var space = get_world_3d().direct_space_state
		var hit = space.intersect_ray(cast)
		if "position" in hit:
			_last_ground_y = hit.position.y

			var target = hit.position.y + _desired_float
			if global_position.y > target - 0.1:
				_y_move = -y_speed
			elif global_position.y < target - 0.1:
				_y_move = y_speed

func _process(delta):
	super._process(delta)

	Stats.stats["bug/pcalls"] += 1

	if dead:
		flying = false
		_y_move = 0.0

	if _fly_sound.playing != flying:
		if flying:
			_fly_sound.play()
		else:
			_fly_sound.stop()

	if dead:
		move_direction = Vector3.ZERO
		rig.position = _rig_base_position + (Vector3.DOWN * 0.1)
		if not shell.is_on_floor():
			rotate_y(0.2)

		return

	_bite_time -= delta
	nav_agent.path_height_offset = global_position.y - _last_ground_y

	if flying:
		rig.position = _rig_base_position + Vector3(0.0, sin(rig._fly_time * 2.0) * 0.1, 0.0)
	else:
		rig.position = _rig_base_position

	if not flying and not move_direction.is_zero_approx() and shell.is_on_floor():
		if _footstep_time < 0.1:
			_footstep_time += delta
		else:
			_clip_sounds.play_random_clip(0, 5)
			_footstep_time = 0.0

	if is_multiplayer_authority():
		energy = 30.0

		if flying:
			if _current_attack_target != null:
				_desired_float = 1.0
			else:
				_desired_float = 2.0
			for hitbox in hitboxes:
				if hitbox.current_hitpoints <= 0.0:
					flying = false
					break
		elif not shell.is_on_floor():
			rotate_y(0.2)
			return

		if _current_attack_target != null and _current_attack_target.dead:
			_current_attack_target = null

		if _current_attack_target == null:
			for content in get_perception_volumes_contents():
				var is_attackable = (
					(content is HiFiCharacterShell or content is LoFiCharacterShell) and
					not content.character is BugCharacter and
					not content.character.dead
				)
				if is_attackable:
					_current_attack_target = content.character

			_waypoint_time += delta
			if _move_towards(_current_waypoint) or _waypoint_time > 10.0:
				_current_waypoint = _next_waypoint()
				_waypoint_time = 0.0
		else:
			var final_dist = (global_position - _current_attack_target.global_position).length()
			if final_dist > 2.0:
				if (nav_agent.target_position - _current_attack_target.global_position).length() > 2.0:
					nav_agent.target_position = _current_attack_target.global_position
				_move_towards(nav_agent.get_next_path_position())
			elif _move_towards(_current_attack_target.global_position):
				if _bite_time < 0.0:
					_clip_sounds.play_clip_rpc(5, randi_range(0, 1))

					World.current.spawn_projectile(
						load("res://projectiles/punch_projectile.tscn"),
						_current_attack_target.global_position,
						Vector3.ZERO, self
					)
					_bite_time = 0.5

func update_velocity(delta):
	super.update_velocity(delta)

	velocity.y = _y_move

func _move_towards(target: Vector3) -> bool:
	var delta = (target - global_position)
	delta.y = 0.0

	var prev_y = move_direction.y

	if delta.length() < 0.4:
		move_direction = Vector3.ZERO
		move_direction.y = prev_y
		return true

	look_at(target)
	global_rotation.y += PI * 0.5
	global_rotation.x = 0.0
	global_rotation.z = 0.0

	move_direction = delta.normalized().rotated(Vector3.UP, -global_rotation.y)
	move_direction.y = prev_y
	return false

func _next_waypoint() -> Vector3:
	return _spawn_position + Vector3(0.5 - randf(), 0.0, 0.5 - randf()) * 6.0

func get_current_speed():
	if flying:
		return speed
	return speed * 0.5

func do_hit_cosmetics(from: Projectile):
	_hit_sounds.play_random_clip(0, 3)
