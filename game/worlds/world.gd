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
var _character_cull_targets: Array[Node3D]
var _culled_items: Array[Item]

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

	var culled_characters = 0
	for cull_target in _character_cull_targets:
		var cull = true
		for observer in _observers:
			if observer.global_position.distance_to(cull_target.global_position) < character_update_cull_distance:
				cull = false
				break

		cull_target.character.set_culled(cull)
		if cull:
			culled_characters += 1

	Stats.stats["c/culled"] = culled_characters
	Stats.stats["c/all"] = characters.get_children().size()

	var tick_cull_items: Array[Item] = []
	for cull_target in items.get_children():
		var cull = true
		for observer in _observers:
			if observer.global_position.distance_to(cull_target.global_position) < item_update_cull_distance:
				cull = false
				break

		if cull:
			tick_cull_items.push_back(cull_target)

	var tick_unculled_items: Array[Item] = []
	for item in _culled_items:
		var cull = true
		for observer in _observers:
			if observer.global_position.distance_to(item.hard_culled_position) < item_update_cull_distance:
				cull = false
				break

		if cull:
			continue

		tick_unculled_items.push_back(item)

	for item in tick_cull_items:
		item.hard_culled_position = item.global_position
		items.remove_child(item)
		_culled_items.push_back(item)

	for item in tick_unculled_items:
		items.add_child(item)
		_culled_items.remove_at(_culled_items.find(item))
		item.global_position = item.hard_culled_position

	Stats.stats["i/culled"] = _culled_items.size()
	Stats.stats["i/active"] = items.get_children().size()

func get_character(character_name: String) -> Character:
	return characters.get_node(character_name).character

func get_item(item_name: String) -> Item:
	return items.get_node(item_name)

func spawn_projectile(projectile_type: Resource, global_pos: Vector3, global_rot: Vector3):
	var instance = projectile_type.instantiate()
	projectiles.add_child(instance, true)
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
	else:
		_character_cull_targets.push_back(shell)

	shell.global_position = global_pos

func spawn_item(item: Item, global_pos: Vector3):
	items.add_child(item, true)
	item.global_position = global_pos

# TODO: Smarter and also these need to have readable names.
func get_static_object_ref(object: StaticObject) -> String:
	return object.get_path()

func get_static_object(ref: String) -> StaticObject:
	return get_node(ref)
