extends Node2D
## Particle engine for fireworks.
##
## Particles are Dictionaries integrated with gravity + optional drag.
## Drawing path: one draw_texture_rect per particle (against a precomputed
## radial gradient sparkle texture) + one draw_polyline for trails. The field
## node uses BLEND_MODE_ADD so overlapping particles bloom naturally.
##
## Smoke-style particles (snake / smoke bomb) live on a separate non-additive
## sub-node so dark/opaque colors render correctly.

const DEFAULT_GRAVITY := 180.0
const DEFAULT_DRAG := 0.35
const MAX_PARTICLES := 8000

var particles: Array = []          # additive (sparks)
var smoke_particles: Array = []    # normal blend (smoke / snake)
var rng := RandomNumberGenerator.new()
var spark_tex: Texture2D
var _smoke_layer: SmokeLayer

# Endless-ramp state (used by _launch_endless / _process_endless)
var endless_active := false
var endless_interval := 0.5
var endless_ramp_period := 5.0
var endless_ramp_factor := 0.75
var endless_next_fire := 0.0
var endless_next_ramp := 0.0
var endless_ground := Vector2.ZERO
var endless_elapsed := 0.0

# Perf logging state
var perf_active := false
var _perf_label_text := ""
var _perf_t := 0.0
var _perf_next_sample := 0.0
var _perf_sample_interval := 0.5
var _perf_sim_usec := 0   # cumulative for current sample window
var _perf_draw_usec := 0
var _perf_sim_frames := 0
var _perf_draw_frames := 0
# Aggregates across the whole test
var _perf_peak_sparks := 0
var _perf_peak_smoke := 0
var _perf_peak_total := 0
var _perf_peak_t := 0.0
var _perf_min_fps := 9999.0
var _perf_min_fps_t := 0.0
var _perf_min_fps_total := 0
var _perf_fps_sum := 0.0
var _perf_fps_samples := 0
var _perf_first_below_60 := -1.0
var _perf_first_below_60_total := 0
var _perf_first_below_30 := -1.0
var _perf_first_below_30_total := 0

func _ready() -> void:
	# Sparks render here via per-particle draw_texture_rect (rich glow) on
	# additive blend. Smoke goes to a separate non-additive sub-layer.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = mat
	spark_tex = _build_spark_texture()
	_smoke_layer = SmokeLayer.new()
	_smoke_layer.field = self
	_smoke_layer.z_index = -1
	add_child(_smoke_layer)
	rng.randomize()
	set_process(true)

func _build_spark_texture() -> Texture2D:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var max_r := float(size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var t: float = clamp(d / max_r, 0.0, 1.0)
			# Soft halo + bright core composite
			var halo: float = pow(1.0 - t, 2.6) * 0.45
			var core: float = pow(max(0.0, 1.0 - d / 4.5), 1.4) * 0.95
			var a: float = clamp(halo + core, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

# --- Public API ----------------------------------------------------------

## Launch a firework described by `fw` (from FireworkBursts.catalog()).
## `ground_pos` is the X/Y of the ground where mortars take off.
func launch(fw: Dictionary, ground_pos: Vector2) -> void:
	var kind: String = fw.get("launch", "mortar")
	match kind:
		"ground":
			# Ground-level fireworks (sparkler, fountain, spinner, etc.)
			# Spawn at ground directly — no mortar.
			FireworkBursts.burst(fw.id, self, ground_pos + Vector2(0, -20))
		"cake":
			# Cake launches multiple mortars sequentially from a wide base.
			_launch_cake(fw, ground_pos)
		"none":
			# Used by "snake" / smoke bomb — stay on ground, no mortar.
			FireworkBursts.burst(fw.id, self, ground_pos + Vector2(0, -20))
		"barrage":
			_launch_barrage(fw, ground_pos)
		"endless":
			_launch_endless(fw, ground_pos)
		"show":
			_launch_apocalypse_show(fw, ground_pos)
		_:
			_launch_mortar(fw, ground_pos)

func _launch_barrage(fw: Dictionary, ground_pos: Vector2) -> void:
	# Configurable stress test. Each barrage tier sets shots + window in the
	# catalog entry. Skips #11 (cake — already a barrage) and #51-54 (other tiers).
	var shots: int = fw.get("shots", 50)
	var window: float = fw.get("window", 10.0)
	var catalog: Array = FireworkBursts.catalog()
	var pool: Array = []
	for entry in catalog:
		if entry.id < 51 and entry.id != 11:
			pool.append(entry)
	pool.shuffle()
	var screen_w := 1920.0
	var margin := 120.0
	var fire_one = func(sub_fw: Dictionary, x_pos: float):
		var sub_ground := Vector2(x_pos, ground_pos.y)
		launch(sub_fw, sub_ground)
	for i in shots:
		var entry: Dictionary = pool[i % pool.size()]
		var delay := (float(i) / float(max(shots - 1, 1))) * window + rng.randf_range(-0.05, 0.05)
		var x_pos := rng.randf_range(margin, screen_w - margin)
		_schedule(max(0.0, delay), fire_one.bind(entry, x_pos))

func _launch_endless(fw: Dictionary, ground_pos: Vector2) -> void:
	# Endless ramp: fires a firework every `interval` sec, ramping the rate
	# faster every `ramp_period` sec until Space is pressed (which advances
	# to the next catalog entry, clearing the field).
	var initial_interval: float = fw.get("interval", 0.5)
	var ramp_period: float = fw.get("ramp_period", 5.0)
	var ramp_factor: float = fw.get("ramp_factor", 0.75)
	endless_active = true
	endless_interval = initial_interval
	endless_ramp_period = ramp_period
	endless_ramp_factor = ramp_factor
	endless_next_fire = 0.05
	endless_next_ramp = ramp_period
	endless_ground = ground_pos

## Spawn a particle. `overrides` is a Dictionary of field overrides.
func spawn(pos: Vector2, vel: Vector2, overrides: Dictionary = {}) -> void:
	if particles.size() >= MAX_PARTICLES:
		return
	var p := {
		"pos": pos,
		"vel": vel,
		"color": overrides.get("color", Color(1, 0.8, 0.4)),
		"size": overrides.get("size", 2.0),
		"life": overrides.get("life", 1.2),
		"life_max": overrides.get("life", 1.2),
		"gravity": overrides.get("gravity", DEFAULT_GRAVITY),
		"drag": overrides.get("drag", DEFAULT_DRAG),
		"fade": overrides.get("fade", "linear"),
		"trail_len": overrides.get("trail_len", 0),
		"trail": [],
		"trail_color": overrides.get("trail_color", Color(1, 0.7, 0.3, 0.6)),
		"halo": overrides.get("halo", 1.0),
		"mode": overrides.get("mode", "spark"),
		"strobe_rate": overrides.get("strobe_rate", 18.0),
		"strobe_t": 0.0,
		"flicker_seed": rng.randf() * 10.0,
		"meta": overrides.get("meta", {}),
	}
	particles.append(p)

## Spawn a smoke particle (rendered on a non-additive sub-layer).
func spawn_smoke(pos: Vector2, vel: Vector2, overrides: Dictionary = {}) -> void:
	if smoke_particles.size() >= MAX_PARTICLES:
		return
	var p := {
		"pos": pos,
		"vel": vel,
		"color": overrides.get("color", Color(0.5, 0.5, 0.5)),
		"size": overrides.get("size", 6.0),
		"life": overrides.get("life", 2.0),
		"life_max": overrides.get("life", 2.0),
		"gravity": overrides.get("gravity", -10.0),
		"drag": overrides.get("drag", 0.4),
		"alpha_max": overrides.get("alpha_max", 0.5),
		"size_growth": overrides.get("size_growth", 0.0),
	}
	smoke_particles.append(p)

## Clear everything — called between firework types.
func clear_all() -> void:
	particles.clear()
	smoke_particles.clear()
	_scheduled.clear()
	endless_active = false

# --- Launch helpers -----------------------------------------------------

func _launch_mortar(fw: Dictionary, ground_pos: Vector2) -> void:
	var apex_y: float = fw.get("apex", 340.0)    # target apex Y in screen coords
	var hang: float = fw.get("hang", 0.15)        # seconds to hold/drop after apex
	var color_primary: Color = fw.get("color", Color(1, 0.7, 0.3))
	var trail_kind: String = fw.get("trail_kind", "fire")
	var rise_h: float = ground_pos.y - apex_y
	var g := 260.0   # reduced gravity on ascending mortar — looks smoother
	var v_y: float = -sqrt(2.0 * g * rise_h)
	var t_apex: float = -v_y / g
	var mortar := {
		"pos": ground_pos,
		"vel": Vector2(rng.randf_range(-15.0, 15.0), v_y),
		"color": color_primary,
		"size": 1.6 if trail_kind == "smoke" else 2.2,
		"life": t_apex + hang + 0.05,
		"life_max": t_apex + hang + 0.05,
		"gravity": g,
		"drag": 1.0,
		"fade": "none",
		"trail_len": 0 if trail_kind == "smoke" else 14,
		"trail": [],
		"trail_color": Color(0.7, 0.7, 0.7, 0.4) if trail_kind == "smoke" else Color(1.0, 0.75, 0.35, 0.85),
		"halo": 0.6 if trail_kind == "smoke" else 1.3,
		"mode": "mortar",
		"strobe_rate": 0.0,
		"strobe_t": 0.0,
		"flicker_seed": 0.0,
		"meta": {
			"fw_id": fw.id,
			"apex_y": apex_y,
			"hang_time": hang,
			"post_apex": 0.0,
			"burst_queued": true,
			"trail_kind": trail_kind,
		},
	}
	particles.append(mortar)

func _launch_cake(fw: Dictionary, ground_pos: Vector2) -> void:
	# Cake: series of mortars fanning out with mixed sub-effects.
	var shots: int = fw.get("shots", 7)
	var spread: float = fw.get("spread", 420.0)
	var palette: Array = fw.get("palette", [Color(1, 0.3, 0.3), Color(0.3, 1, 0.4), Color(0.3, 0.5, 1.0), Color(1, 1, 0.3)])
	var sub_id: int = fw.get("sub_id", 15)
	var fire_one = func(x_off: float, col: Color):
		var start := ground_pos + Vector2(x_off, 0)
		var apex := Vector2(ground_pos.x + x_off * 0.6, ground_pos.y - rng.randf_range(420.0, 540.0))
		_launch_mortar_to({
			"id": sub_id, "color": col, "hang": 0.08
		}, start, apex)
	for i in shots:
		var t = float(i) / max(1, shots - 1)
		var x_off = lerp(-spread * 0.5, spread * 0.5, t)
		var delay = float(i) * 0.32
		var col: Color = palette[i % palette.size()]
		_schedule(delay, fire_one.bind(x_off, col))

func _launch_mortar_to(fw: Dictionary, start: Vector2, apex: Vector2) -> void:
	var rise_h = start.y - apex.y
	var g := 260.0
	var v_y = -sqrt(2.0 * g * rise_h)
	var t_apex = -v_y / g
	var v_x = (apex.x - start.x) / t_apex
	var mortar := {
		"pos": start,
		"vel": Vector2(v_x, v_y),
		"color": fw.get("color", Color(1, 0.8, 0.3)),
		"size": 2.0,
		"life": t_apex + fw.get("hang", 0.08) + 0.05,
		"life_max": t_apex + fw.get("hang", 0.08) + 0.05,
		"gravity": g,
		"drag": 1.0,
		"fade": "none",
		"trail_len": 12,
		"trail": [],
		"trail_color": Color(1.0, 0.75, 0.35, 0.85),
		"halo": 1.3,
		"mode": "mortar",
		"strobe_rate": 0.0,
		"strobe_t": 0.0,
		"flicker_seed": 0.0,
		"meta": {
			"fw_id": fw.id,
			"apex_y": apex.y,
			"hang_time": fw.get("hang", 0.08),
			"post_apex": 0.0,
			"burst_queued": true,
		},
	}
	particles.append(mortar)

var _scheduled: Array = []
func _schedule(delay: float, fn: Callable) -> void:
	_scheduled.append({"t": delay, "fn": fn})

func _custom_pop(cp: Dictionary, pos: Vector2) -> void:
	match cp.get("kind", ""):
		"roman_pop":
			var col: Color = cp.get("color", Color(1, 0.7, 0.3))
			# Small flash
			spawn(pos, Vector2.ZERO, {
				"color": col, "size": 8.0, "life": 0.2,
				"gravity": 0.0, "drag": 0.0, "halo": 2.5, "fade": "ease",
			})
			for k in 22:
				var a = rng.randf() * TAU
				var s = rng.randf_range(70, 160)
				spawn(pos, Vector2(cos(a), sin(a)) * s, {
					"color": col, "size": 1.6, "life": 1.1,
					"gravity": 150.0, "drag": 0.35,
					"halo": 0.9, "fade": "flicker",
				})

# --- Update loop --------------------------------------------------------

func _process(delta: float) -> void:
	_process_scheduled(delta)
	_process_endless(delta)
	var sim_t0 := Time.get_ticks_usec()
	_process_particles(delta)
	_process_smoke(delta)
	_perf_sim_usec += Time.get_ticks_usec() - sim_t0
	_perf_sim_frames += 1
	queue_redraw()
	if perf_active:
		_perf_sample(delta)

func _process_endless(delta: float) -> void:
	if not endless_active:
		return
	endless_elapsed += delta
	endless_next_fire -= delta
	endless_next_ramp -= delta
	if endless_next_fire <= 0.0:
		endless_next_fire = endless_interval
		var catalog := FireworkBursts.catalog()
		var pool: Array = []
		for entry in catalog:
			if entry.id < 51 and entry.id != 11:
				pool.append(entry)
		var sub_fw: Dictionary = pool[rng.randi() % pool.size()]
		var x_pos := rng.randf_range(120.0, 1800.0)
		launch(sub_fw, Vector2(x_pos, endless_ground.y))
	if endless_next_ramp <= 0.0:
		endless_next_ramp = endless_ramp_period
		endless_interval = max(endless_interval * endless_ramp_factor, 0.05)

func stop_endless() -> void:
	endless_active = false
	endless_elapsed = 0.0

# --- Apocalypse Show ---------------------------------------------------

var host_ref = null   # set by world.gd; used for camera shake + fade

func _launch_apocalypse_show(_fw: Dictionary, ground_pos: Vector2) -> void:
	# 60-second cinematic: distant meteors in the background throughout,
	# a curated firework crescendo, then a single huge meteor strike + fade.
	var screen_w := 1920.0
	var ground_y: float = ground_pos.y

	# --- Distant meteors throughout 0-58s ---
	# Emit one every ~0.8-1.6s (random). Each is a small bright streak
	# that crosses from upper area diagonally toward the horizon.
	var t := 0.5
	while t < 57.5:
		var jitter: float = rng.randf_range(-0.3, 0.3)
		_schedule(t + jitter, _spawn_distant_meteor)
		t += rng.randf_range(0.85, 1.6)

	# --- Curated firework arc ---
	# Helper to fire a specific catalog id at a screen X
	var fire_at = func(fw_id: int, x: float):
		var entry: Dictionary = _catalog_entry(fw_id)
		launch(entry, Vector2(x, ground_y))

	# Opening 0-15s: 5 measured shells
	_schedule(1.5,  fire_at.bind(21, screen_w * 0.50))   # peony center
	_schedule(4.5,  fire_at.bind(22, screen_w * 0.30))   # chrysanth left
	_schedule(7.5,  fire_at.bind(23, screen_w * 0.70))   # dahlia right
	_schedule(10.5, fire_at.bind(24, screen_w * 0.50))   # willow center
	_schedule(13.5, fire_at.bind(25, screen_w * 0.35))   # palm

	# Build 15-35s: 9 shells, increasing variety
	var build_times := [15.5, 17.5, 19.5, 22.0, 24.5, 27.0, 29.5, 32.0, 34.0]
	var build_ids   := [21,   27,   28,   25,   22,   36,   24,   31,   23]
	var build_xs    := [0.65, 0.40, 0.55, 0.70, 0.30, 0.50, 0.65, 0.45, 0.55]
	for i in build_times.size():
		_schedule(build_times[i], fire_at.bind(build_ids[i], screen_w * build_xs[i]))

	# Heavy 35-50s: 14 shells, often overlapping
	var heavy_times := [35.5, 36.5, 37.7, 38.5, 39.6, 41.0, 41.8, 43.0, 44.2, 45.4, 46.5, 47.7, 48.5, 49.4]
	var heavy_ids   := [22,   25,   26,   28,   35,   24,   38,   29,   22,   32,   25,   27,   24,   28]
	var heavy_xs    := [0.30, 0.70, 0.50, 0.20, 0.80, 0.45, 0.60, 0.35, 0.65, 0.50, 0.25, 0.75, 0.50, 0.40]
	for i in heavy_times.size():
		_schedule(heavy_times[i], fire_at.bind(heavy_ids[i], screen_w * heavy_xs[i]))

	# Frantic finale 50-57s: barrage stacking
	var finale_times := [50.0, 50.5, 51.0, 51.4, 51.9, 52.3, 52.8, 53.2, 53.7, 54.1, 54.6, 55.0, 55.4, 55.9, 56.3]
	var finale_ids   := [25,   24,   28,   22,   38,   35,   25,   24,   29,   28,   26,   22,   25,   24,   40]
	for i in finale_times.size():
		var fx: float = rng.randf_range(0.18, 0.82)
		_schedule(finale_times[i], fire_at.bind(finale_ids[i], screen_w * fx))

	# --- Pause 57-58s (no fireworks scheduled) — sky goes quiet ---

	# --- The strike: meteor enters at 57.6s, impacts at 60.0s ---
	_schedule(57.6, _strike_meteor_enter.bind(Vector2(screen_w * 0.5, ground_y)))
	_schedule(60.0, _strike_meteor_impact.bind(Vector2(screen_w * 0.5, ground_y - 20)))
	# Begin fade to black at impact
	_schedule(60.0, _begin_fade_to_black)
	# Return to menu after fade completes + hold
	_schedule(63.5, _show_complete)

func _catalog_entry(id: int) -> Dictionary:
	var cat := FireworkBursts.catalog()
	for entry in cat:
		if entry.id == id:
			return entry
	return {}

func _spawn_distant_meteor() -> void:
	# Distant meteor: small dim head + long fading trail. Trajectory from
	# upper area diagonally toward the horizon. Render via the additive
	# layer so it glows like a real distant streak.
	var screen_w := 1920.0
	var skyline_y := 880.0  # approximate horizon line
	var from_left := rng.randf() < 0.5
	var start_x: float
	var end_x: float
	if from_left:
		start_x = rng.randf_range(-50.0, screen_w * 0.4)
		end_x = start_x + rng.randf_range(220.0, 480.0)
	else:
		start_x = rng.randf_range(screen_w * 0.6, screen_w + 50.0)
		end_x = start_x - rng.randf_range(220.0, 480.0)
	var start_y: float = rng.randf_range(60.0, 320.0)
	var end_y: float = rng.randf_range(skyline_y - 240.0, skyline_y - 40.0)
	var travel_time: float = rng.randf_range(2.4, 3.8)
	var v: Vector2 = (Vector2(end_x, end_y) - Vector2(start_x, start_y)) / travel_time
	# Color: warm white -> warm orange/red mix
	var hue_pick := rng.randf()
	var col: Color
	if hue_pick < 0.55:
		col = Color(1.0, 0.92, 0.78)
	elif hue_pick < 0.85:
		col = Color(1.0, 0.78, 0.45)
	else:
		col = Color(1.0, 0.55, 0.32)
	spawn(Vector2(start_x, start_y), v, {
		"color": col,
		"size": rng.randf_range(0.9, 1.4),
		"life": travel_time,
		"gravity": 6.0,
		"drag": 0.95,
		"trail_len": rng.randi_range(20, 32),
		"trail_color": Color(col.r * 0.9, col.g * 0.7, col.b * 0.5, 0.55),
		"halo": 0.55,   # smaller halo => looks distant
		"fade": "ease",
	})

func _strike_meteor_enter(impact_pos: Vector2) -> void:
	# Single huge meteor entering from upper area, fast trajectory toward
	# the impact point. Travel time 2.4s so it lands at the scheduled impact.
	var travel_time := 2.4
	var start := Vector2(impact_pos.x + 380.0, -120.0)
	var v := (impact_pos - start) / travel_time
	# Two tightly-overlapping particles for a thicker trail
	for k in 2:
		var size := 4.6 if k == 0 else 3.1
		spawn(start + Vector2(k * 4.0, k * 2.0), v + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)), {
			"color": Color(1.0, 0.55, 0.18),
			"size": size,
			"life": travel_time + 0.05,
			"gravity": 12.0,
			"drag": 0.99,
			"trail_len": 56,
			"trail_color": Color(1.0, 0.42, 0.12, 0.85),
			"halo": 1.6,
			"fade": "none",
		})
	# Streaming embers shed from the meteor every 0.04s
	var emit_ember = func():
		var t_now := Time.get_ticks_usec()
		_strike_ember(start, v, t_now)
	for i in 60:
		_schedule(i * 0.04, emit_ember)

func _strike_ember(_start: Vector2, _v: Vector2, _t: int) -> void:
	# Helper called repeatedly during meteor descent — emits ember at
	# the meteor's current rough position. We approximate by reading the
	# longest-trail meteor particle position.
	# Find a particle with mode "spark" and large halo near the strike trajectory.
	var pos: Vector2 = Vector2.ZERO
	var found := false
	for p in particles:
		if p.halo >= 1.5 and p.size >= 3.0:
			pos = p.pos
			found = true
			break
	if not found:
		return
	for k in 2:
		var a := rng.randf() * TAU
		var s := rng.randf_range(40, 110)
		spawn(pos + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)),
			Vector2(cos(a), sin(a)) * s, {
			"color": Color(1.0, 0.65, 0.2),
			"size": 1.1,
			"life": 0.7,
			"gravity": 90.0,
			"drag": 0.35,
			"trail_len": 4,
			"trail_color": Color(1.0, 0.5, 0.18, 0.6),
			"halo": 0.7,
			"fade": "flicker",
		})

func _strike_meteor_impact(impact_pos: Vector2) -> void:
	# Massive flash + shockwave + debris + smoke. This is the climax.
	# 1) Screen-filling white flash particle (very large, very short life)
	spawn(impact_pos + Vector2(0, -40), Vector2.ZERO, {
		"color": Color(1.0, 0.95, 0.85),
		"size": 220.0,
		"life": 0.45,
		"gravity": 0.0, "drag": 0.0,
		"halo": 5.0, "fade": "ease",
	})
	# 2) Inner ground-burst flame
	for i in 80:
		var a: float = -PI * 0.5 + rng.randf_range(-0.55, 0.55)
		var s: float = rng.randf_range(360, 760)
		spawn(impact_pos, Vector2(cos(a), sin(a)) * s, {
			"color": Color(1.0, 0.55, 0.18),
			"size": 2.4, "life": 1.6,
			"gravity": 220.0, "drag": 0.30,
			"halo": 1.4, "fade": "flicker",
			"trail_len": 6,
			"trail_color": Color(1.0, 0.45, 0.15, 0.7),
		})
	# 3) Outer shockwave ring (horizontal-biased)
	var ring_count := 110
	for i in ring_count:
		var a: float = TAU * (float(i) / ring_count)
		var s := 540.0
		spawn(impact_pos, Vector2(cos(a) * s, sin(a) * s * 0.4), {
			"color": Color(1.0, 0.85, 0.55),
			"size": 2.6, "life": 1.0,
			"gravity": 80.0, "drag": 0.18,
			"halo": 1.6, "fade": "ease",
		})
	# 4) Debris rocks lofted high
	for i in 35:
		var a: float = -PI * 0.5 + rng.randf_range(-0.7, 0.7)
		var s: float = rng.randf_range(320, 620)
		spawn(impact_pos, Vector2(cos(a), sin(a)) * s, {
			"color": Color(0.9, 0.55, 0.25),
			"size": 1.8, "life": 2.4,
			"gravity": 320.0, "drag": 0.15,
			"trail_len": 8, "halo": 0.9, "fade": "flicker",
			"trail_color": Color(1.0, 0.5, 0.2, 0.65),
		})
	# 5) Massive smoke plume on the smoke layer
	for k in 40:
		var a: float = rng.randf() * TAU
		var s: float = rng.randf_range(40, 220)
		spawn_smoke(impact_pos, Vector2(cos(a), sin(a) * 0.8) * s, {
			"color": Color(0.35, 0.30, 0.28),
			"size": 28.0, "life": 5.0,
			"gravity": -22.0, "drag": 0.4,
			"alpha_max": 0.85, "size_growth": 32.0,
		})
	# 6) Camera shake — heavy, sustained-ish via repeated scheduled bumps
	if host_ref != null and host_ref.has_method("request_shake"):
		host_ref.request_shake(40.0)
	for i in 6:
		_schedule(i * 0.18, _aftershake)

func _aftershake() -> void:
	if host_ref != null and host_ref.has_method("request_shake"):
		host_ref.request_shake(18.0)

func _begin_fade_to_black() -> void:
	if host_ref != null and host_ref.has_method("start_fade_to_black"):
		host_ref.start_fade_to_black(2.5)

func _show_complete() -> void:
	if host_ref != null and host_ref.has_method("on_show_complete"):
		host_ref.on_show_complete()

# --- Perf logging API ---------------------------------------------------

func start_perf_log(test_label: String) -> void:
	perf_active = true
	_perf_label_text = test_label
	_perf_t = 0.0
	_perf_next_sample = 0.0
	_perf_sim_usec = 0
	_perf_draw_usec = 0
	_perf_sim_frames = 0
	_perf_draw_frames = 0
	_perf_peak_sparks = 0
	_perf_peak_smoke = 0
	_perf_peak_total = 0
	_perf_peak_t = 0.0
	_perf_min_fps = 9999.0
	_perf_min_fps_t = 0.0
	_perf_min_fps_total = 0
	_perf_fps_sum = 0.0
	_perf_fps_samples = 0
	_perf_first_below_60 = -1.0
	_perf_first_below_60_total = 0
	_perf_first_below_30 = -1.0
	_perf_first_below_30_total = 0
	print("")
	print("=== STRESS TEST: %s ===" % _perf_label_text)
	print("t       fps  sparks  smoke  sched  sim_us  draw_us")

func stop_perf_log() -> void:
	if not perf_active:
		return
	perf_active = false
	var avg_fps: float = 0.0
	if _perf_fps_samples > 0:
		avg_fps = _perf_fps_sum / float(_perf_fps_samples)
	print("")
	print("=== SUMMARY: %s (%.1fs) ===" % [_perf_label_text, _perf_t])
	print("Peak sparks:  %d" % _perf_peak_sparks)
	print("Peak smoke:   %d" % _perf_peak_smoke)
	print("Peak total:   %d at t=%.1fs" % [_perf_peak_total, _perf_peak_t])
	print("Min FPS:      %d at t=%.1fs (%d particles)" % [int(_perf_min_fps), _perf_min_fps_t, _perf_min_fps_total])
	print("Avg FPS:      %d" % int(avg_fps))
	if _perf_first_below_60 >= 0.0:
		print("First < 60:   t=%.1fs at %d particles" % [_perf_first_below_60, _perf_first_below_60_total])
	else:
		print("First < 60:   never")
	if _perf_first_below_30 >= 0.0:
		print("First < 30:   t=%.1fs at %d particles" % [_perf_first_below_30, _perf_first_below_30_total])
	else:
		print("First < 30:   never")
	print("============================")
	print("")

func _perf_sample(delta: float) -> void:
	_perf_t += delta
	_perf_next_sample -= delta
	# Track peaks every frame (cheap)
	var sparks: int = particles.size()
	var smoke: int = smoke_particles.size()
	var total: int = sparks + smoke
	if sparks > _perf_peak_sparks: _perf_peak_sparks = sparks
	if smoke > _perf_peak_smoke: _perf_peak_smoke = smoke
	if total > _perf_peak_total:
		_perf_peak_total = total
		_perf_peak_t = _perf_t
	var fps: float = Engine.get_frames_per_second()
	_perf_fps_sum += fps
	_perf_fps_samples += 1
	if fps < _perf_min_fps:
		_perf_min_fps = fps
		_perf_min_fps_t = _perf_t
		_perf_min_fps_total = total
	if _perf_first_below_60 < 0.0 and fps < 60.0 and _perf_t > 0.5:
		_perf_first_below_60 = _perf_t
		_perf_first_below_60_total = total
	if _perf_first_below_30 < 0.0 and fps < 30.0 and _perf_t > 0.5:
		_perf_first_below_30 = _perf_t
		_perf_first_below_30_total = total
	# Periodic snapshot to console
	if _perf_next_sample <= 0.0:
		_perf_next_sample = _perf_sample_interval
		var sim_us: int = 0
		var draw_us: int = 0
		if _perf_sim_frames > 0:
			sim_us = _perf_sim_usec / _perf_sim_frames
		if _perf_draw_frames > 0:
			draw_us = _perf_draw_usec / _perf_draw_frames
		print("%5.1fs  %3d  %5d   %4d   %4d   %5d   %5d" % [
			_perf_t, int(fps), sparks, smoke, _scheduled.size(), sim_us, draw_us
		])
		_perf_sim_usec = 0
		_perf_draw_usec = 0
		_perf_sim_frames = 0
		_perf_draw_frames = 0

func _process_smoke(delta: float) -> void:
	var i := smoke_particles.size() - 1
	while i >= 0:
		var p = smoke_particles[i]
		p.vel.y += p.gravity * delta
		p.vel *= pow(max(p.drag, 0.0001), delta)
		p.pos += p.vel * delta
		p.size += p.size_growth * delta
		p.life -= delta
		if p.life <= 0.0:
			smoke_particles.remove_at(i)
		i -= 1

func _process_scheduled(delta: float) -> void:
	for s in _scheduled:
		s.t -= delta
	var ready = _scheduled.filter(func(s): return s.t <= 0.0)
	_scheduled = _scheduled.filter(func(s): return s.t > 0.0)
	for s in ready:
		s.fn.call()

func _process_particles(delta: float) -> void:
	var i := particles.size() - 1
	while i >= 0:
		var p = particles[i]
		var mode: String = p.mode

		# Integration
		p.vel.y += p.gravity * delta
		var drag_factor: float = p.drag
		p.vel *= pow(max(drag_factor, 0.0001), delta)
		p.pos += p.vel * delta

		# Trail push
		if p.trail_len > 0:
			p.trail.append(p.pos)
			if p.trail.size() > p.trail_len:
				p.trail.pop_front()

		# Strobe timing
		if p.strobe_rate > 0.0:
			p.strobe_t += delta

		# Mortar-specific: detect apex, trigger burst
		if mode == "mortar":
			var meta: Dictionary = p.meta
			# Trigger when EITHER the mortar reaches the planned apex Y
			# OR its upward motion has stopped (vel.y >= 0) — whichever
			# comes first, since drag/numerics may shave off the planned peak.
			var at_or_past_apex: bool = (p.pos.y <= meta.apex_y) or (p.vel.y >= 0.0)
			if at_or_past_apex and meta.burst_queued:
				p.gravity = 60.0
				meta.post_apex += delta
				if meta.post_apex >= meta.hang_time:
					meta.burst_queued = false
					if meta.has("custom_pop"):
						_custom_pop(meta.custom_pop, p.pos)
					else:
						FireworkBursts.burst(meta.fw_id, self, p.pos)
					particles.remove_at(i)
					i -= 1
					continue
			# Emit trail behind mortar — fire sparks (default) or smoke puffs.
			var trail_kind: String = p.meta.get("trail_kind", "fire")
			if trail_kind == "smoke":
				if rng.randf() < 0.85:
					spawn_smoke(p.pos + Vector2(rng.randf_range(-3, 3), rng.randf_range(0, 6)),
						Vector2(rng.randf_range(-12, 12), rng.randf_range(20, 40)), {
						"color": Color(0.55, 0.55, 0.55), "size": 5.5,
						"life": 1.4, "gravity": -8.0, "drag": 0.5,
						"alpha_max": 0.45, "size_growth": 8.0,
					})
			elif rng.randf() < 0.6:
				var spark_vel = -p.vel * 0.08 + Vector2(rng.randf_range(-25, 25), rng.randf_range(-10, 20))
				spawn(p.pos, spark_vel, {
					"color": Color(1.0, 0.9, 0.4),
					"size": 1.1, "life": 0.35,
					"gravity": 120.0, "drag": 0.05,
					"halo": 0.6,
				})

		# Life tick
		p.life -= delta
		if p.life <= 0.0:
			# Mortar safety net: if life expired before burst fired, force-fire it.
			if mode == "mortar" and p.meta.get("burst_queued", false):
				p.meta.burst_queued = false
				if p.meta.has("custom_pop"):
					_custom_pop(p.meta.custom_pop, p.pos)
				elif p.meta.get("fw_id", -1) > 0:
					FireworkBursts.burst(p.meta.fw_id, self, p.pos)
			# On-death sub-burst (crossette, multibreak, etc.)
			if p.meta.has("on_death"):
				var on_death: Dictionary = p.meta.on_death
				match on_death.get("kind", ""):
					"split":
						var n: int = on_death.get("count", 4)
						var spd: float = on_death.get("speed", 120.0)
						var life: float = on_death.get("life", 0.5)
						var col: Color = on_death.get("color", p.color)
						for k in n:
							var a = (TAU / n) * k + rng.randf_range(-0.15, 0.15)
							var v = Vector2(cos(a), sin(a)) * spd
							spawn(p.pos, v, {
								"color": col, "size": 1.8, "life": life,
								"gravity": 140.0, "drag": 0.4, "halo": 1.0,
								"trail_len": 4,
								"trail_color": Color(col.r, col.g, col.b, 0.4),
							})
					"pop":
						FireworkBursts.burst(on_death.get("id", 15), self, p.pos)
					"drone_burst":
						# Each drone bursts into its own colored mini-peony.
						var col: Color = on_death.get("color", p.color)
						for k in 24:
							var a = (TAU / 24) * k + rng.randf_range(-0.08, 0.08)
							var spd = rng.randf_range(140, 220)
							spawn(p.pos, Vector2(cos(a), sin(a)) * spd, {
								"color": col, "size": 1.8, "life": 1.4,
								"gravity": 130.0, "drag": 0.4,
								"halo": 1.0, "fade": "linear",
								"trail_len": 4,
								"trail_color": Color(col.r, col.g, col.b, 0.5),
							})
			particles.remove_at(i)
		i -= 1

# --- Drawing ------------------------------------------------------------

func _draw() -> void:
	# Per-particle textured rect for the rich glow look, plus a single
	# batched draw_multiline_colors call for every trail segment in the
	# field (trails are <100 particles even under heavy load on average,
	# but batching them collapses what was the dominant draw cost).
	var t0 := Time.get_ticks_usec()
	var segs := PackedVector2Array()
	var cols := PackedColorArray()
	for p in particles:
		var life_t: float = clamp(p.life / p.life_max, 0.0, 1.0)
		var alpha: float = 1.0
		match p.fade:
			"linear":
				alpha = life_t
			"ease":
				alpha = life_t * life_t
			"none":
				alpha = 1.0
			"flicker":
				alpha = life_t * (0.55 + 0.45 * sin((p.life_max - p.life) * 28.0 + p.flicker_seed))
			"strobe":
				alpha = life_t * (1.0 if (sin(p.strobe_t * p.strobe_rate) > 0.0) else 0.12)
			"shimmer":
				alpha = life_t * (0.4 + 0.6 * sin((p.life_max - p.life) * 45.0 + p.flicker_seed))
			_:
				alpha = life_t
		if alpha <= 0.001:
			continue
		# Trail collection (will be drawn in one batched call below)
		var trail: Array = p.trail
		var trail_n: int = trail.size()
		if trail_n >= 2:
			var tc: Color = p.trail_color
			var base_a: float = tc.a * alpha * 0.9
			var inv_n: float = 1.0 / float(trail_n - 1)
			for i in trail_n - 1:
				segs.append(trail[i])
				segs.append(trail[i + 1])
				var fade_a: float = float(i) * inv_n * base_a
				var seg_col := Color(tc.r, tc.g, tc.b, fade_a)
				cols.append(seg_col)
				cols.append(seg_col)
		# Spark texture — single draw call per particle
		var c: Color = p.color
		var radius: float = p.size * 3.4 * p.halo
		var d: float = radius * 2.0
		var rect := Rect2(p.pos.x - radius, p.pos.y - radius, d, d)
		var draw_color := Color(
			min(c.r + 0.25, 1.0),
			min(c.g + 0.25, 1.0),
			min(c.b + 0.25, 1.0),
			alpha
		)
		draw_texture_rect(spark_tex, rect, false, draw_color)
	if segs.size() > 0:
		draw_multiline_colors(segs, cols, 1.4)
	_perf_draw_usec += Time.get_ticks_usec() - t0
	_perf_draw_frames += 1
