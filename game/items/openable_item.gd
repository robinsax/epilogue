class_name OpenableItem extends Item

@export var lid: Node3D = null
@export var lid_open_anchor: Node3D = null

var _lid_base_position: Vector3
var _lid_base_rotation: Vector3

func _ready():
	super._ready()

	_lid_base_position = lid.position
	_lid_base_rotation = lid.rotation

func _process(delta):
	super._process(delta)

	if current_slot != null and current_slot.inventory._owner is Character and current_slot.inventory._owner.in_inventory:
		lid.position = lid_open_anchor.position
		lid.rotation = lid_open_anchor.rotation
	else:
		lid.position = _lid_base_position
		lid.rotation = _lid_base_rotation
