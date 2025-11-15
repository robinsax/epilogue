extends Node3D

var INVENTORY_ROTATION_DAMP = 100.0

var _character = null
var _active_interact_target = null
var _in_inventory = false
var _escaped = false

var _inventory_ui = null
var _inventory_viewport = null
var _inventory_camera = null
var _inventory_lamp = null

var _inventory_drag_basis = null
var _inventory_rotation_basis = 0.0
var _inventory_rotation = 0.0

var _hud_active_interact_target = null

func bind(character):
	_character = character

func _ready():
	_inventory_ui = $ui/inventory
	_inventory_viewport = $ui/inventory/player_view_container/player_view
	_inventory_camera = $ui/inventory/player_view_container/player_view/camera
	_inventory_lamp = $ui/inventory/player_view_container/player_view/lamp
	
	_hud_active_interact_target = $ui/hud/active_interact_target
	
	_character.camera.current = true
	_character.mesh.set_layer_mask_value(2, true) # inventory_view render layer

func interact():
	if _active_interact_target == null:
		return
		
	_character.interact_with(_active_interact_target)

func _inventory_mouse_pos():
	return _inventory_viewport.get_viewport().get_mouse_position()

func _input(event):
	if not _in_inventory:
		return

	if event.is_action_pressed("inventory_drop") and _active_interact_target != null:
		_active_interact_target.inventory_attach(null)

	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			_inventory_drag_basis = _inventory_mouse_pos()
			_inventory_rotation_basis = _inventory_rotation
		else:
			_inventory_drag_basis = null
	
	if event is InputEventMouse and _inventory_drag_basis:
		_inventory_rotation = _inventory_rotation_basis + (
			(_inventory_drag_basis.x - _inventory_mouse_pos().x) /
			INVENTORY_ROTATION_DAMP
		)

func _process(delta):
	if _active_interact_target != null:
		_hud_active_interact_target.text = _active_interact_target.interact_info()
	else:
		_hud_active_interact_target.text = ""
	
	if Input.is_action_just_pressed("escape"):
		_escaped = !_escaped

	_in_inventory = Input.is_action_pressed("inventory")

	if _escaped:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif _in_inventory:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if _in_inventory:
		_inventory_ui.show()
		
		_inventory_viewport.size = Vector2(1.0, 1.0) * get_viewport().size.y * 0.75
	else:
		_inventory_ui.hide()

	var base_position = _character.global_position
	_inventory_camera.position = (
		base_position - (
			_character.transform.basis * 2.0 *
			Vector3(sin(_inventory_rotation), 0.0, cos(_inventory_rotation))
		)
	)
	_inventory_lamp.position = _inventory_camera.position
	_inventory_camera.look_at(base_position)
	_inventory_lamp.look_at(base_position)

func _physics_process(delta):
	_active_interact_target = null

	var space = get_world_3d().direct_space_state
	
	var screen_position = null
	var camera = null
	if _in_inventory:
		screen_position = _inventory_mouse_pos()
		camera = _inventory_camera
	else:
		screen_position = get_viewport().size / 2.0
		camera = _character.camera
	
	var ray_origin = camera.project_ray_origin(screen_position)
	var ray_end = ray_origin + camera.project_ray_normal(screen_position) * 100.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)

	var result = space.intersect_ray(query)
	if "collider" not in result:
		return

	var collider = result["collider"]
	if collider.has_method("interacted_by"):
		_active_interact_target = collider
