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
const MAX_PARTICLES := 30000

var particles: Array = []          # additive (sparks)
var smoke_particles: Array = []    # normal blend (smoke / snake)
var rng := RandomNumberGenerator.new()
var spark_tex: Texture2D
var _smoke_layer: SmokeLayer
var _mm_instance: MultiMeshInstance2D
var _mm: MultiMesh

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
var _perf_mm_usec := 0
var _perf_sim_frames := 0
var _perf_draw_frames := 0
var _perf_mm_frames := 0
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
	# Trails are drawn via _draw on this node — needs additive blend.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = mat
	spark_tex = _build_spark_texture()

	# MultiMeshInstance2D for per-particle sparks — one GPU draw call for all.
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	_mm.mesh = quad
	_mm.instance_count = MAX_PARTICLES
	_mm.visible_instance_count = 0
	_mm_instance = MultiMeshInstance2D.new()
	_mm_instance.multimesh = _mm
	_mm_instance.texture = spark_tex
	var mm_mat := CanvasItemMaterial.new()
	mm_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_mm_instance.material = mm_mat
	add_child(_mm_instance)

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
	var mm_t0 := Time.get_ticks_usec()
	_populate_multimesh()
	_perf_mm_usec += Time.get_ticks_usec() - mm_t0
	_perf_mm_frames += 1
	queue_redraw()
	if perf_active:
		_perf_sample(delta)

func _populate_multimesh() -> void:
	var n: int = particles.size()
	_mm.visible_instance_count = n
	for i in n:
		var p: Dictionary = particles[i]
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
		var c: Color = p.color
		var radius: float = p.size * 3.4 * p.halo
		var d: float = radius * 2.0
		var t: Transform2D = Transform2D(Vector2(d, 0), Vector2(0, d), p.pos)
		_mm.set_instance_transform_2d(i, t)
		_mm.set_instance_color(i, Color(
			min(c.r + 0.25, 1.0),
			min(c.g + 0.25, 1.0),
			min(c.b + 0.25, 1.0),
			alpha
		))

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

# --- Perf logging API ---------------------------------------------------

func start_perf_log(test_label: String) -> void:
	perf_active = true
	_perf_label_text = test_label
	_perf_t = 0.0
	_perf_next_sample = 0.0
	_perf_sim_usec = 0
	_perf_draw_usec = 0
	_perf_mm_usec = 0
	_perf_sim_frames = 0
	_perf_draw_frames = 0
	_perf_mm_frames = 0
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
	print("t       fps  sparks  smoke  sched  sim_us  mm_us  draw_us")

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
		var mm_us: int = 0
		if _perf_sim_frames > 0:
			sim_us = _perf_sim_usec / _perf_sim_frames
		if _perf_draw_frames > 0:
			draw_us = _perf_draw_usec / _perf_draw_frames
		if _perf_mm_frames > 0:
			mm_us = _perf_mm_usec / _perf_mm_frames
		print("%5.1fs  %3d  %5d   %4d   %4d   %5d  %5d   %5d" % [
			_perf_t, int(fps), sparks, smoke, _scheduled.size(), sim_us, mm_us, draw_us
		])
		_perf_sim_usec = 0
		_perf_draw_usec = 0
		_perf_mm_usec = 0
		_perf_sim_frames = 0
		_perf_draw_frames = 0
		_perf_mm_frames = 0

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
	# Spark bodies are drawn via the MultiMeshInstance2D child. _draw here
	# only handles trails (mortars + a small fraction of effects) — that's
	# typically <100 particles even under heavy load.
	var t0 := Time.get_ticks_usec()
	for p in particles:
		if p.trail.size() <= 1:
			continue
		var life_t: float = clamp(p.life / p.life_max, 0.0, 1.0)
		var alpha: float = life_t
		match p.fade:
			"ease": alpha = life_t * life_t
			"none": alpha = 1.0
			"flicker": alpha = life_t * (0.55 + 0.45 * sin((p.life_max - p.life) * 28.0 + p.flicker_seed))
			"strobe": alpha = life_t * (1.0 if (sin(p.strobe_t * p.strobe_rate) > 0.0) else 0.12)
			"shimmer": alpha = life_t * (0.4 + 0.6 * sin((p.life_max - p.life) * 45.0 + p.flicker_seed))
		if alpha <= 0.01:
			continue
		var tc: Color = p.trail_color
		var trail_color := Color(tc.r, tc.g, tc.b, tc.a * alpha * 0.9)
		draw_polyline(PackedVector2Array(p.trail), trail_color, max(p.size * 0.55, 0.9), false)
	_perf_draw_usec += Time.get_ticks_usec() - t0
	_perf_draw_frames += 1
