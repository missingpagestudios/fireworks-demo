extends CanvasLayer
## Centered banner + small controls hint.

const SCREEN := Vector2(1920, 1080)

@onready var _banner: Control = Control.new()
@onready var _num_label: Label = Label.new()
@onready var _name_label: Label = Label.new()
@onready var _category_label: Label = Label.new()
@onready var _controls_label: Label = Label.new()

var _banner_alpha := 0.0
var _target_alpha := 0.0

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

	_controls_label.text = "[Space] next   [B] prev   [R] replay   [A] toggle auto"
	_controls_label.add_theme_font_size_override("font_size", 18)
	_controls_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.6))
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.anchor_left = 0.0
	_controls_label.anchor_right = 1.0
	_controls_label.offset_top = 1040
	_controls_label.offset_bottom = 1070
	add_child(_controls_label)

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
