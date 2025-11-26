class_name HitboxInfo extends Control

static var _HITBOX_STATUS_ICONS = {
	"low": load("res://assets/ui/warning.png"),
	"critical": load("res://assets/ui/critical_hitbox.png"),
	"crippled": load("res://assets/ui/broken.png")
}

var hitbox: CharacterHitbox

var _label: Label
var _values: Label
var _statuses: Array[TextureRect]

func _ready():
	_label = $Label
	_values = $Values
	_statuses = [$Status1, $Status2, $Status3]

func _process(delta: float):
	_label.text = hitbox.label

	_values.text = str(int(hitbox.current_hitpoints)) + "/" + str(int(hitbox.hitpoints))

	var status_keys: Array[String] = []
	if hitbox.current_hitpoints <= 0.0:
		status_keys.push_back("crippled")
	elif hitbox.current_hitpoints < hitbox.hitpoints / 2.0:
		status_keys.push_back("low")

	if hitbox.is_cripple_lethal:
		status_keys.push_back("critical")

	for i in _statuses.size():
		var ui = _statuses[i]
		if i >= status_keys.size():
			ui.texture = null
			continue
		else:
			ui.texture = _HITBOX_STATUS_ICONS[status_keys[i]]
