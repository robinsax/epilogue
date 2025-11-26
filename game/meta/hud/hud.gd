class_name HUD extends Control

@export var visual_energy_multiplier = 4.0

static var _ITEM_TYPE_ICONS = {
	"handgun": load("res://assets/ui/handgun.png"),
	"vest": load("res://assets/ui/vest.png"),
	"belt": load("res://assets/ui/belt.png"),
	"holster": load("res://assets/ui/holster.png"),
	"robotaug": load("res://assets/ui/augmentation.png"),
	"robotheadaug": load("res://assets/ui/head_augmentation.png"),
	"bottompack": load("res://assets/ui/bottom_clip.png"),
	"toppack": load("res://assets/ui/top_clip.png")
}
static var _HITBOX_STATUS_UI = load("res://meta/hud/hitbox_info.tscn")
static var _OBJECT_INTERACT_ICON = load("res://assets/ui/interact.png")

var possession: PlayerPossession

var _crosshair: Control
var _crosshair_small: Control
var _cursor: Control
var _debug_stats: Label
var _mouse_locked: bool

var _interact_group: Control
var _interact_main: Label
var _interact_detail: Label
var _interact_size_indicators: Array[Control]
var _interact_type: TextureRect

var _slot_group: Control
var _slot_detail: Label
var _slot_size_indicators: Array[Control]
var _slot_type: TextureRect

class HotkeyUI:
	var label: Label
	var type: TextureRect
	var group: Control

var _status_group: Control
var _hp_value: Label
var _hp_total: Label
var _enery_value: Label
var _enery_total: Label
var _energy_burn: Label
var _hotkey_uis: Array[HotkeyUI]
var _status_loading_hint: Control
var _hitbox_statuses_root: Control
var _status_check_time: float

var _chat_input: LineEdit
var _chat_just_closed: bool

var _compass_group: Control
var _compass_label: Label

func _ready() -> void:
	Stats.stats["ik/active"] = 0
	_crosshair = $Crosshair
	_crosshair_small = $CrosshairSmall
	_debug_stats = $DebugStats
	_cursor = $Cursor

	_interact_group = $Interact
	_interact_main = $Interact/Main
	_interact_detail = $Interact/Detail
	_interact_size_indicators = [$Interact/Size1, $Interact/Size2, $Interact/Size3]
	_interact_type = $Interact/Type

	_slot_group = $Slot
	_slot_detail = $Slot/Detail
	_slot_type = $Slot/Type
	_slot_size_indicators = [$Slot/Size1, $Slot/Size2, $Slot/Size3]

	_status_group = $StatusCheck
	_hp_value = $StatusCheck/Status/HP/Value
	_hp_total = $StatusCheck/Status/HP/Total
	_enery_value = $StatusCheck/Status/Energy/Value
	_enery_total = $StatusCheck/Status/Energy/Total
	_hotkey_uis = []
	for i in 5:
		var base_name = "StatusCheck/Hotkeys/" + str(i + 1)
		var instance = HotkeyUI.new()
		instance.group = get_node(base_name)
		instance.label = get_node(base_name + "/Label")
		instance.type = get_node(base_name + "/Type")
		_hotkey_uis.push_back(instance)
	_status_loading_hint = $StatusCheck/ExtendedStatus/LoadingHint
	_hitbox_statuses_root = $StatusCheck/ExtendedStatus/Hitboxes
	_energy_burn = $StatusCheck/ExtendedStatus/EnergyBurn

	_chat_input = $Chat/Input
	_chat_input.text_submitted.connect(_send_chat)

	_compass_group = $StatusCheck/ESP/Compass
	_compass_label = $StatusCheck/ESP/Compass/Indicator

func _send_chat(text: String):
	possession.character.say(text)
	_chat_input.text = ""
	_chat_input.release_focus()
	_chat_input.visible = false
	_chat_just_closed = true

func _process(delta: float):
	var stats_str = "fps: " + str(Engine.get_frames_per_second()) + "\n"
	for key in Stats.stats:
		stats_str += key + ": " + str(Stats.stats[key]) + "\n"
	_debug_stats.text = stats_str
	Stats.stats["ik/active"] = 0

	_cursor.visible = not _mouse_locked
	_cursor.position = get_viewport().get_mouse_position()
	_crosshair.visible = (
		not possession.in_inventory and
		(possession._interact_target != null or possession.character.aiming)
	)
	_crosshair_small.visible = not possession.in_inventory

	# Slot target
	if not _mouse_locked and possession._slot_target != null:
		_slot_group.visible = true
		_slot_group.position = possession._camera.unproject_position(possession._slot_target.global_position)
		_slot_detail.text = possession._slot_target.label
		_slot_type.texture = _ITEM_TYPE_ICONS.get(possession._slot_target.required_tag, null)

		for i in 3:
			_slot_size_indicators[i].visible = i < possession._slot_target.size
	else:
		_slot_group.visible = false

	# Interact target.
	var final_size = 0
	if possession._interact_target != null:
		_interact_group.visible = true
		_interact_main.text = possession._interact_target.label

		if possession.in_inventory:
			_interact_group.position = get_viewport().get_mouse_position()

		if possession._interact_target is Item:
			_interact_type.texture = null
			for tag in possession._interact_target.tags:
				if tag in _ITEM_TYPE_ICONS:
					_interact_type.texture = _ITEM_TYPE_ICONS[tag]
					break

			_interact_detail.text = possession._interact_target.get_detail_string()
			final_size = possession._interact_target.size
		else:
			_interact_group.visible = false
	elif possession.character.object_interact_target != null:
		_interact_group.visible = true
		_interact_main.text = possession.character.object_interact_target.label
		_interact_detail.text = possession.character.object_interact_target.detail_string
		if not possession.character.object_interact_target.default_interaction.is_null():
			_interact_type.texture = _OBJECT_INTERACT_ICON
		else:
			_interact_type.texture = null
	else:
		_interact_group.visible = false
		_interact_main.text = ""
		_interact_type.texture = null
		_interact_detail.text = ""

	for i in _interact_size_indicators.size():
		_interact_size_indicators[i].visible = i < final_size

	# Status.
	var character = possession._character
	_status_group.visible = character.checking_status
	_hp_value.text = str(int(character.get_current_hitpoints()))
	_hp_total.text = "/" + str(int(character.get_total_hitpoints()))
	_enery_value.text = str(int(character.energy * visual_energy_multiplier))
	_enery_total.text = "/" + str(int(character.initial_energy * visual_energy_multiplier))

	if character.checking_status:
		_status_check_time += delta
		if _status_check_time < 1.0:
			_status_loading_hint.visible = true
			_energy_burn.visible = false
			for child in _hitbox_statuses_root.get_children():
				_hitbox_statuses_root.remove_child(child)
		else:
			_status_loading_hint.visible = false
			_energy_burn.visible = true
			_energy_burn.text = str(int(character.energy_burn_rate * visual_energy_multiplier * -1.0)) + "/sec"
			if _hitbox_statuses_root.get_children().size() == 0:
				var k = 0
				for hitbox in character.hitboxes:
					if hitbox.group_with != null:
						continue

					var status_ui: Control = _HITBOX_STATUS_UI.instantiate()
					status_ui.hitbox = hitbox
					_hitbox_statuses_root.add_child(status_ui)
					status_ui.position = Vector2(0.0, 30.0 * k)
					k += 1
	else:
		_status_check_time = 0.0

	# Hotkeys.
	for i in _hotkey_uis.size():
		var ui = _hotkey_uis[i]
		ui.type.texture = null
		var hotkey = "hotkey_" + str(i + 1)
		var item = possession._hotkeys.get(hotkey)
		if item != null:
			ui.label.text = item.label
			for tag in item.tags:
				if tag in _ITEM_TYPE_ICONS:
					ui.type.texture = _ITEM_TYPE_ICONS[tag]
					break
		else:
			ui.label.text = ""

	# Compass.
	var has_compass = false
	for slot in character.augmentation_slots:
		if slot.item is CompassItem:
			has_compass = true
			break

	if not has_compass:
		_compass_group.visible = false
	else:
		_compass_group.visible = true
		_compass_group.rotation = character.global_rotation.y
		_compass_label.rotation = -character.global_rotation.y

func set_mouse_locked(locked: bool):
	_mouse_locked = locked

func _input(event: InputEvent) -> void:
	if event.is_action_released("open_chat"):
		if _chat_just_closed:
			_chat_just_closed = false
		else:
			_chat_input.visible = true
			_chat_input.grab_focus()
