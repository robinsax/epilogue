class_name World extends Node3D

@export var character_update_cull_distance: float = 60.0
@export var item_update_cull_distance: float = 60.0

var characters: Node3D
var items: Node3D
var projectiles: Node3D
var statics: Node3D
var environment_generator: EnvironmentGenerator

var _local_dynamic: Node3D
var _observers: Array[Node3D]
var _culled_items: Array[Node3D]
var _culled_characters: Array[Node3D]

static var current: World = null

signal prepared()

func _ready():
	characters = $Characters
	items = $Items
	projectiles = $Projectiles
	statics = $Static
	_local_dynamic = $LocalDynamic
	environment_generator = get_node_or_null("Static/EnvironmentGenerator")

	_observers = []

	Stats.stats["bug/pcalls"] = 0

	World.current = self

	if environment_generator == null:
		_report_prepared()
	else:
		environment_generator.root_terrain_ready.connect(_report_prepared)

func _report_prepared():
	prepared.emit()

func _process(delta: float):
	if not is_multiplayer_authority():
		# TODO: NO CULLS ON CLIENT?!?!
		return

	Stats.stats["ops/uncull"] = 0
	Stats.stats["ops/cull"] = 0

	_cull_type(characters, _culled_characters, character_update_cull_distance)

	Stats.stats["c/culled"] = _culled_characters.size()
	Stats.stats["c/active"] = characters.get_children().size()

	_cull_type(items, _culled_items as Array[Node3D], item_update_cull_distance)

	Stats.stats["i/culled"] = _culled_items.size()
	Stats.stats["i/active"] = items.get_children().size()

func _cull_type(root: Node3D, culled_set: Array[Node3D], cull_distance: float):
	var tick_cull: Array[Node3D] = []
	for target in root.get_children():
		var cull = true
		for observer in _observers:
			if observer.global_position.distance_to(target.global_position) < cull_distance:
				cull = false
				break

		if cull:
			tick_cull.push_back(target)

	var tick_uncull: Array[Node3D] = []
	for target in culled_set:
		var cull = true
		for observer in _observers:
			if observer.global_position.distance_to(target.hard_culled_position) < cull_distance:
				cull = false
				break

		if cull:
			continue

		tick_uncull.push_back(target)

	for target in tick_cull:
		Stats.stats["ops/cull"] += 1
		target.hard_culled_position = target.global_position
		root.remove_child(target)
		_cull_toggle_node(target, true)
		culled_set.push_back(target)

	for target in tick_uncull:
		Stats.stats["ops/uncull"] += 1
		root.add_child(target)
		culled_set.remove_at(culled_set.find(target))
		_cull_toggle_node(target, false)
		target.global_position = target.hard_culled_position

func _cull_toggle_node(node: Node, cull: bool):
	if cull:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		node.process_mode = Node.PROCESS_MODE_INHERIT
	node.set_process(not cull)
	node.set_physics_process(not cull)

	for child in node.get_children():
		_cull_toggle_node(child, cull)

func get_character(character_name: String) -> Character:
	return characters.get_node(character_name).character

func get_item(item_name: String) -> Item:
	return items.get_node(item_name)

func spawn_projectile(projectile_type: Resource, global_pos: Vector3, global_rot: Vector3, source: Character = null):
	var instance = projectile_type.instantiate()
	projectiles.add_child(instance, true)
	instance.source = source
	instance.global_position = global_pos
	instance.global_rotation = global_rot
	instance.is_cosmetic = not is_multiplayer_authority()

func remove_projectile(projectile: Projectile):
	projectiles.remove_child(projectile)

func spawn_local_dynamic(node: Node3D, global_pos: Vector3):
	_local_dynamic.add_child(node)
	node.global_position = global_pos

func remove_local_dynamic(node: Node3D):
	_local_dynamic.remove_child(node)

func spawn_character(shell: Node3D, global_pos: Vector3):
	characters.add_child(shell, true)
	if shell.get_node("Character").is_world_observer:
		_observers.push_back(shell)

	shell.global_position = global_pos

func spawn_item(item: Item, global_pos: Vector3):
	items.add_child(item, true)
	item.global_position = global_pos

# TODO: Smarter and also these need to have readable names.
func get_static_object_ref(object: StaticObject) -> String:
	return object.get_path()

func get_static_object(ref: String) -> StaticObject:
	return get_node(ref)
