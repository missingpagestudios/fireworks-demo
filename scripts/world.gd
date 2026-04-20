extends Node2D
## Sequencer: walks through all 50 fireworks with banner + timed launches.

const SCREEN := Vector2(1920, 1080)
const GROUND_Y := 960.0

@onready var _field: Node2D = $FireworkField
@onready var _hud: CanvasLayer = $HUD
@onready var _camera: Camera2D = $Camera2D

var _catalog: Array = []
var _idx := 0
var _state := "banner"   # banner -> launching -> settling -> next
var _state_time := 0.0
var _auto := true
var _camera_shake_time := 0.0
var _camera_shake_strength := 0.0

func _ready() -> void:
	_catalog = FireworkBursts.catalog()
	_idx = 0
	_start_banner()

func _process(delta: float) -> void:
	_state_time += delta
	_update_camera(delta)

	match _state:
		"banner":
			if _state_time >= 2.2 and _auto:
				_launch_current()
		"launching":
			if _state_time >= _catalog[_idx].get("settle_time", 5.0):
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

func _start_banner() -> void:
	var fw = _catalog[_idx]
	_hud.show_banner(_idx + 1, _catalog.size(), fw.name, fw.category)
	_state = "banner"
	_state_time = 0.0

func _launch_current() -> void:
	var fw = _catalog[_idx]
	_hud.fade_out()
	var ground_x: float = SCREEN.x * 0.5
	_field.launch(fw, Vector2(ground_x, GROUND_Y))
	_state = "launching"
	_state_time = 0.0
	# Brief camera shake for big bursts
	var shake: float = fw.get("shake", 0.0)
	if shake > 0.0:
		_camera_shake_time = 0.35
		_camera_shake_strength = shake

func _advance() -> void:
	_idx = (_idx + 1) % _catalog.size()
	_field.clear_all()
	_start_banner()

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
