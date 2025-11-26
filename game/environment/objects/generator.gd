class_name GeneratorObject extends StaticObject

@export var fuel_burn_rate: float = 0.02
@export var running_material: Material = null

@export var is_running: bool = false
@export var fuel_remaining: float = 0.0

var _smoke: GPUParticles3D
var _mesh: MeshInstance3D
var _run_sound: AudioStreamPlayer3D
var _start_sound: ClippedAudioPlayer
var _fill_interact: ObjectInteractTarget
var _start_interact: ButtonInteractTarget
var _run_time: float

func _ready():
	_smoke = $Smoke
	_mesh = $Mesh
	_fill_interact = $FuelFill
	_run_sound = $RunSound
	_start_sound = $StartSound
	_start_interact = $StartButton
	_start_interact.button_press_callback = _on_start

func _process(delta: float) -> void:
	_smoke.emitting = is_running
	if is_running:
		if is_multiplayer_authority():
			fuel_remaining -= fuel_burn_rate * delta
			if fuel_remaining <= 0.0:
				fuel_remaining = 0.0
				is_running = false

		_mesh.set_surface_override_material(0, running_material)
		if not _run_sound.playing:
			if _run_time < 1.0:
				_run_time += delta
			else:
				_run_sound.play()
	else:
		_mesh.set_surface_override_material(0, null)
		_run_sound.stop()

	_fill_interact.detail_string = str(int(fuel_remaining)) + "L in tank"

func _on_start():
	if fuel_remaining > 0.0:
		_start_sound.play_clip(1)

		if is_multiplayer_authority():
			is_running = true
			_run_time = 0.0
	else:
		_start_sound.play_clip(0)
