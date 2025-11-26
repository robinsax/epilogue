class_name ShieldGeneratorItem extends Item

static var BUBBLE_SCENE = load("res://items/shield_generator_bubble.tscn")

@export var energy_drain_rate: float = 3.0

var _bubble: ShieldGeneratorBubble
var _beams: Node3D

func _ready():
	super._ready()
	_beams = $Beams

func _process(delta):
	super._process(delta)

	var active = (
		current_slot != null and current_slot.required_tag == "robotaug" and
		current_slot.inventory.get_parent().energy > 0.0
	)
	_beams.visible = active
	if active:
		if _bubble == null:
			_bubble = BUBBLE_SCENE.instantiate()
			World.current.spawn_local_dynamic(_bubble, global_position)

		_bubble.global_position = current_slot.inventory.get_parent().global_position
	elif _bubble != null:
		World.current.remove_local_dynamic(_bubble)
		_bubble = null

func update_as_attached(character: RobotBipedCharacter, delta: float):
	character.energy -= energy_drain_rate * delta
