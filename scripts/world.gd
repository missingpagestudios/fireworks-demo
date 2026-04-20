extends Node2D
## Sequencer: walks through fireworks with banner + timed launches.
## Two modes selected from a startup menu:
##   0 — Demo (fireworks 1-50)
##   1 — Stress tests (51-54)

const SCREEN := Vector2(1920, 1080)
const GROUND_Y := 960.0

@onready var _field: Node2D = $FireworkField
@onready var _hud: CanvasLayer = $HUD
@onready var _camera: Camera2D = $Camera2D

var _full_catalog: Array = []
var _active_catalog: Array = []
var _idx := 0
var _state := "menu"   # menu | banner | launching | settled
var _state_time := 0.0
var _auto := true
var _camera_shake_time := 0.0
var _camera_shake_strength := 0.0

func _ready() -> void:
	_full_catalog = FireworkBursts.catalog()
	_hud.field = _field
	_field.host_ref = self
	_show_menu()

func start_fade_to_black(duration: float) -> void:
	_hud.start_fade_to_black(duration)

func start_screen_flash(intensity: float, decay_seconds: float, tint: Color = Color(1, 1, 1)) -> void:
	_hud.start_screen_flash(intensity, decay_seconds, tint)

func on_show_complete() -> void:
	# Apocalypse show finished — return to menu (stays on black until cleared)
	_show_menu()

func _process(delta: float) -> void:
	_state_time += delta
	_update_camera(delta)

	if _state == "menu":
		_handle_menu_input()
		return

	match _state:
		"banner":
			if _state_time >= 2.2 and _auto:
				_launch_current()
		"launching":
			if _state_time >= _active_catalog[_idx].get("settle_time", 5.0):
				if _auto:
					_advance()
				else:
					_state = "settled"
		"settled":
			pass

	if Input.is_action_just_pressed("next_firework"):
		if _state == "banner":
			_launch_current()
		else:
			_advance()
	elif Input.is_action_just_pressed("prev_firework"):
		_idx = max(0, _idx - 1)
		_field.clear_all()
		_start_banner()
	elif Input.is_action_just_pressed("replay_firework"):
		_field.clear_all()
		_start_banner()
	elif Input.is_action_just_pressed("toggle_auto"):
		_auto = not _auto

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if _state == "menu":
			if key == KEY_UP:
				_hud.menu_move(-1)
				get_viewport().set_input_as_handled()
			elif key == KEY_DOWN:
				_hud.menu_move(1)
				get_viewport().set_input_as_handled()
			elif key == KEY_1:
				_start_mode(0)
				get_viewport().set_input_as_handled()
			elif key == KEY_2:
				_start_mode(1)
				get_viewport().set_input_as_handled()
			elif key == KEY_3:
				_start_mode(2)
				get_viewport().set_input_as_handled()
			elif key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE:
				_start_mode(_hud.menu_selected())
				get_viewport().set_input_as_handled()
		else:
			if key == KEY_ESCAPE:
				_show_menu()
				get_viewport().set_input_as_handled()

# --- Menu / mode selection ---------------------------------------------

func _show_menu() -> void:
	_field.stop_perf_log()
	_state = "menu"
	_state_time = 0.0
	_field.clear_all()
	_hud.cancel_fade()
	_hud.show_menu()
	_hud.fade_out()

func _start_mode(mode_idx: int) -> void:
	_hud.hide_menu()
	_hud.cancel_fade()
	if mode_idx == 0:
		_active_catalog = _full_catalog.filter(func(e): return e.id <= 50)
	elif mode_idx == 1:
		_active_catalog = _full_catalog.filter(func(e): return e.id >= 51 and e.id <= 54)
	else:
		_active_catalog = _full_catalog.filter(func(e): return e.id == 55)
	_idx = 0
	_start_banner()

# --- Sequencer ----------------------------------------------------------

func _start_banner() -> void:
	var fw = _active_catalog[_idx]
	_hud.show_banner(_idx + 1, _active_catalog.size(), fw.name, fw.category)
	_state = "banner"
	_state_time = 0.0

func _launch_current() -> void:
	var fw = _active_catalog[_idx]
	_hud.fade_out()
	var ground_x: float = SCREEN.x * 0.5
	_field.launch(fw, Vector2(ground_x, GROUND_Y))
	_state = "launching"
	_state_time = 0.0
	var shake: float = fw.get("shake", 0.0)
	if shake > 0.0:
		_camera_shake_time = 0.35
		_camera_shake_strength = shake
	# Start perf logging for stress tests
	if fw.id >= 51:
		_field.start_perf_log(fw.name)

func _advance() -> void:
	_field.stop_perf_log()
	_idx = (_idx + 1) % _active_catalog.size()
	_field.clear_all()
	_start_banner()

func _handle_menu_input() -> void:
	pass   # handled in _input

# --- Camera shake -------------------------------------------------------

func _update_camera(delta: float) -> void:
	if _camera_shake_time > 0.0:
		_camera_shake_time -= delta
		var t = max(_camera_shake_time / 0.35, 0.0)
		var s = _camera_shake_strength * t
		_camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
	else:
		_camera.offset = Vector2.ZERO

func request_shake(strength: float) -> void:
	_camera_shake_time = 0.35
	_camera_shake_strength = strength
