extends CanvasLayer
## Centered banner + small controls hint.

const SCREEN := Vector2(1920, 1080)

@onready var _banner: Control = Control.new()
@onready var _num_label: Label = Label.new()
@onready var _name_label: Label = Label.new()
@onready var _category_label: Label = Label.new()
@onready var _controls_label: Label = Label.new()
@onready var _perf_label: Label = Label.new()
@onready var _menu: Control = Control.new()
@onready var _menu_title: Label = Label.new()
@onready var _menu_opt1: Label = Label.new()
@onready var _menu_opt2: Label = Label.new()
@onready var _menu_opt3: Label = Label.new()
@onready var _menu_hint: Label = Label.new()
@onready var _fade: ColorRect = ColorRect.new()
@onready var _flash: ColorRect = ColorRect.new()

var _banner_alpha := 0.0
var _target_alpha := 0.0
var field: Node2D    # set by world.gd; used to read live counts
var _fps_smoothed := 60.0
var _menu_selected := 0
var _fade_target := 0.0
var _fade_speed := 1.0
var _flash_alpha := 0.0
var _flash_decay := 1.0
var _flash_hold := 0.0

func _ready() -> void:
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.0
	_banner.anchor_bottom = 1.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)

	_num_label.text = ""
	_num_label.add_theme_font_size_override("font_size", 36)
	_num_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95, 0.9))
	_num_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_num_label.add_theme_constant_override("outline_size", 4)
	_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num_label.anchor_left = 0.5
	_num_label.anchor_right = 0.5
	_num_label.offset_left = -300
	_num_label.offset_right = 300
	_num_label.offset_top = 180
	_num_label.offset_bottom = 230
	_banner.add_child(_num_label)

	_name_label.text = ""
	_name_label.add_theme_font_size_override("font_size", 84)
	_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_name_label.add_theme_constant_override("outline_size", 10)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.anchor_left = 0.5
	_name_label.anchor_right = 0.5
	_name_label.offset_left = -800
	_name_label.offset_right = 800
	_name_label.offset_top = 230
	_name_label.offset_bottom = 340
	_banner.add_child(_name_label)

	_category_label.text = ""
	_category_label.add_theme_font_size_override("font_size", 26)
	_category_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 0.9))
	_category_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_category_label.add_theme_constant_override("outline_size", 4)
	_category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_category_label.anchor_left = 0.5
	_category_label.anchor_right = 0.5
	_category_label.offset_left = -500
	_category_label.offset_right = 500
	_category_label.offset_top = 340
	_category_label.offset_bottom = 380
	_banner.add_child(_category_label)

	_controls_label.text = "[Space] next   [B] prev   [R] replay   [A] toggle auto   [Esc] menu"
	_controls_label.add_theme_font_size_override("font_size", 18)
	_controls_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.anchor_left = 0.0
	_controls_label.anchor_right = 1.0
	_controls_label.offset_top = 1040
	_controls_label.offset_bottom = 1070
	add_child(_controls_label)

	_perf_label.text = ""
	_perf_label.add_theme_font_size_override("font_size", 22)
	_perf_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 0.9))
	_perf_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_perf_label.add_theme_constant_override("outline_size", 4)
	_perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_perf_label.anchor_left = 1.0
	_perf_label.anchor_right = 1.0
	_perf_label.offset_left = -340
	_perf_label.offset_right = -16
	_perf_label.offset_top = 16
	_perf_label.offset_bottom = 110
	add_child(_perf_label)

	# --- Startup menu ---
	_menu.anchor_left = 0.0
	_menu.anchor_right = 1.0
	_menu.anchor_top = 0.0
	_menu.anchor_bottom = 1.0
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.visible = false
	add_child(_menu)

	_menu_title.text = "FIREWORKS 50"
	_menu_title.add_theme_font_size_override("font_size", 96)
	_menu_title.add_theme_color_override("font_color", Color(1, 1, 1))
	_menu_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_menu_title.add_theme_constant_override("outline_size", 12)
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.anchor_left = 0.5
	_menu_title.anchor_right = 0.5
	_menu_title.offset_left = -700
	_menu_title.offset_right = 700
	_menu_title.offset_top = 250
	_menu_title.offset_bottom = 360
	_menu.add_child(_menu_title)

	_menu_opt1.add_theme_font_size_override("font_size", 56)
	_menu_opt1.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_menu_opt1.add_theme_constant_override("outline_size", 6)
	_menu_opt1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_opt1.anchor_left = 0.5
	_menu_opt1.anchor_right = 0.5
	_menu_opt1.offset_left = -700
	_menu_opt1.offset_right = 700
	_menu_opt1.offset_top = 480
	_menu_opt1.offset_bottom = 560
	_menu.add_child(_menu_opt1)

	_menu_opt2.add_theme_font_size_override("font_size", 56)
	_menu_opt2.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_menu_opt2.add_theme_constant_override("outline_size", 6)
	_menu_opt2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_opt2.anchor_left = 0.5
	_menu_opt2.anchor_right = 0.5
	_menu_opt2.offset_left = -700
	_menu_opt2.offset_right = 700
	_menu_opt2.offset_top = 580
	_menu_opt2.offset_bottom = 660
	_menu.add_child(_menu_opt2)

	_menu_opt3.add_theme_font_size_override("font_size", 56)
	_menu_opt3.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_menu_opt3.add_theme_constant_override("outline_size", 6)
	_menu_opt3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_opt3.anchor_left = 0.5
	_menu_opt3.anchor_right = 0.5
	_menu_opt3.offset_left = -700
	_menu_opt3.offset_right = 700
	_menu_opt3.offset_top = 680
	_menu_opt3.offset_bottom = 760
	_menu.add_child(_menu_opt3)

	_menu_hint.text = "[Up/Down or 1/2/3] choose   [Enter] start   [Esc] return to this menu"
	_menu_hint.add_theme_font_size_override("font_size", 22)
	_menu_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.8))
	_menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_hint.anchor_left = 0.0
	_menu_hint.anchor_right = 1.0
	_menu_hint.offset_top = 860
	_menu_hint.offset_bottom = 900
	_menu.add_child(_menu_hint)
	_refresh_menu_highlight()

	# Fade-to-black overlay (always present, alpha 0 by default)
	_fade.color = Color(0, 0, 0, 0)
	_fade.anchor_left = 0.0
	_fade.anchor_right = 1.0
	_fade.anchor_top = 0.0
	_fade.anchor_bottom = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 200
	add_child(_fade)

	# Screen flash overlay — full-screen white burst on impact
	_flash.color = Color(1, 1, 1, 0)
	_flash.anchor_left = 0.0
	_flash.anchor_right = 1.0
	_flash.anchor_top = 0.0
	_flash.anchor_bottom = 1.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 190
	add_child(_flash)

func show_banner(idx: int, total: int, fw_name: String, category: String) -> void:
	_num_label.text = "%d / %d" % [idx, total]
	_name_label.text = fw_name
	_category_label.text = category
	_target_alpha = 1.0
	_banner.modulate.a = 0.0
	_banner_alpha = 0.0

func fade_out() -> void:
	_target_alpha = 0.0

func _process(delta: float) -> void:
	_banner_alpha = move_toward(_banner_alpha, _target_alpha, delta * 2.5)
	_banner.modulate.a = _banner_alpha
	# Fade overlay
	_fade.color.a = move_toward(_fade.color.a, _fade_target, delta * _fade_speed)
	# Flash overlay — hold at peak then linear decay
	if _flash_alpha > 0.0:
		if _flash_hold > 0.0:
			_flash_hold = max(0.0, _flash_hold - delta)
		else:
			_flash_alpha = max(0.0, _flash_alpha - delta * _flash_decay)
		_flash.color.a = _flash_alpha
	# FPS overlay (smoothed) + particle/smoke counts
	var fps: float = Engine.get_frames_per_second()
	_fps_smoothed = lerp(_fps_smoothed, fps, clamp(delta * 4.0, 0.0, 1.0))
	var sparks := 0
	var smokes := 0
	if field != null:
		sparks = field.particles.size()
		smokes = field.smoke_particles.size()
	var fps_color := Color(0.7, 1.0, 0.7) if _fps_smoothed >= 55.0 else (Color(1.0, 0.85, 0.5) if _fps_smoothed >= 30.0 else Color(1.0, 0.4, 0.4))
	_perf_label.add_theme_color_override("font_color", fps_color)
	_perf_label.text = "FPS  %d\nSparks %d\nSmoke  %d" % [int(_fps_smoothed), sparks, smokes]

# --- Menu API -----------------------------------------------------------

func show_menu() -> void:
	_menu.visible = true
	_menu_selected = 0
	_refresh_menu_highlight()

func hide_menu() -> void:
	_menu.visible = false

func menu_visible() -> bool:
	return _menu.visible

func menu_move(delta_idx: int) -> void:
	_menu_selected = (_menu_selected + delta_idx + 3) % 3
	_refresh_menu_highlight()

func menu_selected() -> int:
	return _menu_selected

func _refresh_menu_highlight() -> void:
	var sel := _menu_selected
	_menu_opt1.text = ("> 1.  Walk through 1-50  <" if sel == 0 else "  1.  Walk through 1-50  ")
	_menu_opt2.text = ("> 2.  Stress tests 51-54  <" if sel == 1 else "  2.  Stress tests 51-54  ")
	_menu_opt3.text = ("> 3.  Apocalypse Show (60s)  <" if sel == 2 else "  3.  Apocalypse Show (60s)  ")
	_menu_opt1.add_theme_color_override("font_color", Color(1, 1, 0.5) if sel == 0 else Color(0.7, 0.7, 0.8))
	_menu_opt2.add_theme_color_override("font_color", Color(1, 1, 0.5) if sel == 1 else Color(0.7, 0.7, 0.8))
	_menu_opt3.add_theme_color_override("font_color", Color(1, 0.7, 0.7) if sel == 2 else Color(0.6, 0.5, 0.5))

# --- Fade-to-black -----------------------------------------------------

func start_fade_to_black(duration: float) -> void:
	_fade_target = 1.0
	_fade_speed = 1.0 / max(duration, 0.05)

func cancel_fade() -> void:
	_fade_target = 0.0
	_fade_speed = 4.0
	_fade.color.a = 0.0
	_flash_alpha = 0.0
	_flash_hold = 0.0
	_flash.color.a = 0.0

func start_screen_flash(intensity: float, decay_seconds: float, tint: Color = Color(1, 1, 1), hold_seconds: float = 0.0) -> void:
	# Snap to peak intensity, optionally hold at peak for `hold_seconds`,
	# then decay over `decay_seconds`. Multiple flashes can stack — peak
	# always takes the max.
	if intensity > _flash_alpha:
		_flash_alpha = intensity
	_flash_decay = 1.0 / max(decay_seconds, 0.05)
	_flash_hold = max(_flash_hold, hold_seconds)
	_flash.color = Color(tint.r, tint.g, tint.b, _flash_alpha)
