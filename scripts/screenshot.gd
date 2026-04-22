extends Node2D
## Headless capture tool: launches each of the 50 fireworks one-by-one in a
## SubViewport, waits for peak bloom, then writes a transparent PNG.
##
## Output: user://sprites/firework_<slug>.png   (1024×1024, alpha)
## Filenames match balance_v2_config.json names so Godot can load them by id.
##
## Run: set this scene as main (Project → Project Settings → Application → Run)
## or run via: godot --path . scenes/screenshot.tscn
##
## Controls: press SPACE to begin capture. Status label shows progress.

const SUBVIEW_SIZE := Vector2i(1024, 1024)
const OUTPUT_DIR := "user://sprites"
const SPAWN_GROUND := Vector2(512, 980)   # where mortars/ground fireworks originate

# Per-firework override of when (in seconds) to capture peak bloom.
# Default heuristic: 0.45 × settle_time. Overrides tune visually-best frame.
const PEAK_OVERRIDE := {
	"Sparkler": 1.5,
	"Fountain": 2.5,
	"Ground Spinner": 2.0,
	"Black Snake": 2.0,
	"Smoke Bomb": 2.5,
	"Crackle Ball": 2.2,
	"Firecracker": 0.4,
	"Roman Candle": 3.5,
	"Repeater Cake": 4.0,
	"Mine": 1.0,
	"Salute": 1.2,
	"Pro Salute": 1.4,
	# Sustained / drifting bursts — capture late
	"Willow": 3.5,
	"Strobe Willow": 3.5,
	"Brocade": 3.5,
	"Kamuro": 3.5,
	"Aurora Cascade": 4.5,
	"Drone Swarm": 3.5,
	"Holo Letter": 3.0,
	"Nano Fractal": 3.5,
	"Plasma Vortex": 3.0,
	"Black Hole Shell": 3.5,
	"Kinetic Wireframe": 3.5,
	"Gravity Loop": 3.5,
	"Singularity": 4.0,
}

# Demo firework name → balance_v2 config slug (filename portion).
# Demo predates v2 so a few names diverged. This dict reconciles them.
const NAME_OVERRIDES := {
	"Black Snake": "snake",
	"Ground Spinner": "spinner",
	"Repeater Cake": "repeater",
	"Whistler Shell": "whistler",
	"Small Peony": "peony",
	"Small Chrysanthemum": "chrysanthemum",
	"Strobe Shell": "strobe",
	"Star Shell": "star",
	"Palm Tree": "palm",
	"Ring Shell": "ring",
	"Heart Shell": "heart",
	"Smiley Face": "smiley",
	"Color-Change Peony": "color_change",
	"Pro Peony": "pro_peony",       # explicit (no ambiguity, but consistent)
	"Pro Chrysanthemum": "pro_chrysanthemum",
	"Holo Letter": "holo_letter_a",
	"Kinetic Wireframe": "kinetic_wireframe_cube",
}

@onready var _sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var _field: Node2D = $SubViewportContainer/SubViewport/FireworkField
@onready var _status: Label = $StatusLabel
@onready var _hint: Label = $HintLabel

var _queue: Array = []
var _idx := -1
var _state := "idle"     # idle | armed | waiting | capturing | done
var _state_t := 0.0
var _capture_at := 0.0

func _ready() -> void:
	# Make sure the output dir exists (uses Godot's user data dir,
	# accessible via Project → Open User Data Folder in the editor).
	var out_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(out_abs)

	# SubViewport setup. We render WITH a dark background (additive blending
	# doesn't deposit alpha properly on transparent_bg=true), then chroma-key
	# the dark pixels to alpha in post (_capture_now).
	_sub_viewport.size = SUBVIEW_SIZE
	_sub_viewport.transparent_bg = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Build queue from the canonical 50 (ids 1-50). Skip stress/cinematic.
	var catalog: Array = FireworkBursts.catalog()
	for entry in catalog:
		if int(entry.id) <= 50:
			_queue.append(entry)

	_status.text = "Ready: %d fireworks queued" % _queue.size()
	_hint.text = "Output: %s\nPress SPACE to start capture." % out_abs
	_state = "idle"

func _input(event: InputEvent) -> void:
	if _state == "idle" and event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_SPACE or key == KEY_ENTER:
			_idx = -1
			_advance_to_next()

func _process(delta: float) -> void:
	if _state == "idle" or _state == "done":
		return
	_state_t += delta
	match _state:
		"waiting":
			if _state_t >= _capture_at:
				_state = "capturing"
				_state_t = 0.0
				_capture_now()
		"capturing":
			# Brief settle window after writing PNG before next launch
			if _state_t >= 0.4:
				_advance_to_next()

func _advance_to_next() -> void:
	_idx += 1
	if _idx >= _queue.size():
		_state = "done"
		_status.text = "DONE — saved %d PNGs to %s" % [_queue.size(), ProjectSettings.globalize_path(OUTPUT_DIR)]
		_hint.text = "Press ESC to quit. Files are at the path above."
		return
	var entry: Dictionary = _queue[_idx]
	_field.clear_all()
	# Compute capture timing: per-firework override, else 45% of settle_time.
	var settle: float = float(entry.get("settle_time", 5.0))
	_capture_at = float(PEAK_OVERRIDE.get(entry.name, settle * 0.45))
	# Fire the firework into the SubViewport's field.
	_field.launch(entry, SPAWN_GROUND)
	_status.text = "[%d/%d] %s — capturing at %.1fs" % [
		_idx + 1, _queue.size(), entry.name, _capture_at
	]
	_state = "waiting"
	_state_t = 0.0

func _capture_now() -> void:
	# Wait for the next post-draw so the SubViewport texture is up to date.
	await RenderingServer.frame_post_draw
	var img: Image = _sub_viewport.get_texture().get_image()
	# Vertical flip — SubViewport textures come back y-inverted by default
	# in some renderer paths. Undo if needed (no-op if already correct).
	# Comment this out if your output is upside down.
	# img.flip_y()

	# Chroma-key dark pixels to alpha. The SubViewport renders on the project's
	# default_clear_color (near black, RGB ~ 0.02, 0.02, 0.05). For each pixel,
	# new_alpha = max(R, G, B) — bright firework pixels stay opaque, dark
	# background pixels become transparent.
	_apply_luminance_alpha(img)

	var entry: Dictionary = _queue[_idx]
	var slug := _slugify(entry.name)
	var path := OUTPUT_DIR.path_join("firework_%s.png" % slug)
	var err := img.save_png(path)
	if err != OK:
		push_error("Failed to save %s: %d" % [path, err])
		_status.text = "ERROR saving %s (code %d)" % [path, err]

# Replace each pixel's alpha with its peak channel brightness. Effectively
# converts black background to transparent while preserving all visible
# fireworks pixels at full opacity-by-brightness.
func _apply_luminance_alpha(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var a := max(c.r, max(c.g, c.b))
			# Below this threshold, treat as background (cuts faint compression noise)
			if a < 0.06:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))

func _slugify(name: String) -> String:
	if NAME_OVERRIDES.has(name):
		return NAME_OVERRIDES[name]
	# Default rule: lowercase, spaces → underscore, hyphens dropped, trim.
	var s := name.to_lower()
	s = s.replace("-", "_")
	s = s.replace(" ", "_")
	return s
