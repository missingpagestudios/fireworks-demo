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
# Camera2D in the SubViewport zooms 2.5x — a 1024x1024 viewport at zoom 2.5
# shows roughly a 410x410 world region centered on the camera position.
# That's the right scale for typical 100-300px firework spreads to fill
# most of the frame.
# Mortar/cake/airburst types spawn dead-center; camera also at (512, 512).
const BURST_CENTER := Vector2(512, 512)
# Ground-emitting types (sparkler, fountain, spinner, snake) emit upward —
# spawn near the bottom of the visible window (camera at 512, visible 307-717
# at zoom 2.5) so the upward flow fills the upper portion of the frame.
const GROUND_POS := Vector2(512, 680)

# Per-firework capture timing (seconds after spawn). Now tuned for direct
# burst dispatch (no mortar wait). Default = 1.5s for unspecified entries.
const DEFAULT_CAPTURE := 1.5
const PEAK_OVERRIDE := {
	# Tier 1
	"Sparkler": 1.8,
	"Fountain": 2.5,
	"Ground Spinner": 2.0,
	"Black Snake": 2.5,
	"Smoke Bomb": 2.0,
	"Crackle Ball": 1.0,
	"Firecracker": 0.3,
	"Roman Candle": 3.0,
	"Bottle Rocket": 0.4,
	"Small Mortar": 0.5,
	# Tier 2
	"Repeater Cake": 1.5,
	"Whistler Shell": 0.5,
	"Comet": 1.0,
	"Mine": 0.8,
	"Small Peony": 1.0,
	"Small Chrysanthemum": 1.2,
	"Strobe Shell": 1.5,
	"Salute": 0.5,
	"Glitter Mine": 1.5,
	"Star Shell": 1.5,
	# Tier 3 — Pro Aerial
	"Peony": 1.2,
	"Chrysanthemum": 1.5,
	"Dahlia": 1.5,
	"Willow": 2.5,
	"Palm Tree": 2.0,
	"Crossette": 1.6,
	"Brocade": 2.5,
	"Kamuro": 2.5,
	"Spider": 0.8,
	"Horsetail": 1.5,
	"Ring Shell": 1.0,
	"Heart Shell": 1.2,
	"Smiley Face": 1.2,
	"Star Pattern": 1.2,
	"Multibreak": 1.0,
	"Color-Change Peony": 1.5,
	"Strobe Willow": 2.5,
	"Glitter Palm": 2.2,
	"Hummer": 1.5,
	"Pro Salute": 0.6,
	# Tier 4 — Futuristic. Need to catch the developed visual.
	"Drone Swarm": 1.4,
	"Quantum Bloom": 1.0,
	"Holo Letter": 1.5,
	"Nano Fractal": 1.5,
	"Plasma Vortex": 1.5,
	"Black Hole Shell": 1.2,
	"Aurora Cascade": 2.5,
	"Kinetic Wireframe": 1.8,
	"Gravity Loop": 1.5,
	"Singularity": 2.0,
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

@onready var _sub_viewport: SubViewport = $SubViewport
@onready var _field: Node2D = $SubViewport/FireworkField
@onready var _status: Label = $StatusLabel
@onready var _hint: Label = $HintLabel
@onready var _preview: TextureRect = $PreviewRect

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

	# Live preview of the SubViewport's render target — useful for visually
	# confirming each capture during the run.
	_preview.texture = _sub_viewport.get_texture()

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
	# Capture timing: per-firework override else default 1.5s
	_capture_at = float(PEAK_OVERRIDE.get(entry.name, DEFAULT_CAPTURE))
	# Spawn the burst directly — bypass mortar trajectory. Pos depends on
	# launch type: aerial bursts dead-center, ground emitters lower.
	var pos := _spawn_pos_for(entry)
	var fw_id := int(entry.id)
	# Repeater Cake (id 11) has no direct burst — it's a sequence of mortars.
	# Fire 3 small peonies (id 15) at offsets to convey the multi-burst feel.
	if fw_id == 11:
		FireworkBursts.burst(15, _field, pos + Vector2(-180, -40))
		FireworkBursts.burst(15, _field, pos + Vector2(0, 40))
		FireworkBursts.burst(15, _field, pos + Vector2(180, -40))
	else:
		FireworkBursts.burst(fw_id, _field, pos)
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
			var c: Color = img.get_pixel(x, y)
			var a: float = maxf(c.r, maxf(c.g, c.b))
			# No threshold — preserve all luminance contributions. Pure black BG
			# (RGB 0,0,0) becomes alpha 0 naturally; everything else keeps its
			# brightness as alpha. Faint glows survive instead of being culled.
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))

func _spawn_pos_for(entry: Dictionary) -> Vector2:
	# Ground-level emitters (sparkler, fountain, spinner, snake, mine) shoot
	# upward — spawn lower so the spread stays in frame. Everything else is
	# an airburst that should explode dead-center.
	var kind: String = entry.get("launch", "mortar")
	if kind == "ground" or kind == "none":
		return GROUND_POS
	return BURST_CENTER

func _slugify(name: String) -> String:
	if NAME_OVERRIDES.has(name):
		return NAME_OVERRIDES[name]
	# Default rule: lowercase, spaces → underscore, hyphens dropped, trim.
	var s := name.to_lower()
	s = s.replace("-", "_")
	s = s.replace(" ", "_")
	return s
