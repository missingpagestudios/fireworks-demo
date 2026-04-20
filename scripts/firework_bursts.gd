extends Object
class_name FireworkBursts
## 50 firework burst definitions. Each function receives `field` (FireworkField)
## and `pos` (burst position) and spawns particles into the field.
##
## Registry: catalog() returns the 50 entries used by the sequencer and UI.
## burst(id, field, pos) dispatches to the correct implementation.

# --- Color palettes ----------------------------------------------------

const COL_GOLD := Color(1.0, 0.82, 0.42)
const COL_GOLD_WARM := Color(1.0, 0.72, 0.28)
const COL_SILVER := Color(0.9, 0.9, 1.0)
const COL_WHITE := Color(1.0, 1.0, 1.0)
const COL_RED := Color(1.0, 0.28, 0.22)
const COL_GREEN := Color(0.32, 1.0, 0.42)
const COL_BLUE := Color(0.32, 0.55, 1.0)
const COL_PURPLE := Color(0.78, 0.35, 1.0)
const COL_PINK := Color(1.0, 0.48, 0.78)
const COL_CYAN := Color(0.35, 1.0, 0.95)
const COL_ORANGE := Color(1.0, 0.55, 0.15)
const COL_YELLOW := Color(1.0, 0.95, 0.35)
const COL_SMOKE := Color(0.45, 0.45, 0.5)
const COL_AURORA_GREEN := Color(0.38, 1.0, 0.6)
const COL_AURORA_PURPLE := Color(0.75, 0.5, 1.0)

# --- Catalog -----------------------------------------------------------

static func catalog() -> Array:
	return [
		# --- Backyard / consumer ---
		{"id": 1,  "name": "Sparkler",        "category": "Real — Backyard",   "launch": "ground", "color": COL_GOLD,   "settle_time": 4.5},
		{"id": 2,  "name": "Roman Candle",    "category": "Real — Backyard",   "launch": "ground", "color": COL_RED,    "settle_time": 6.5},
		{"id": 3,  "name": "Bottle Rocket",   "category": "Real — Backyard",   "launch": "mortar", "apex": 520.0, "hang": 0.05, "color": COL_GOLD, "settle_time": 3.5},
		{"id": 4,  "name": "Ground Spinner",  "category": "Real — Backyard",   "launch": "ground", "color": COL_GOLD,   "settle_time": 4.0},
		{"id": 5,  "name": "Fountain",        "category": "Real — Backyard",   "launch": "ground", "color": COL_GOLD,   "settle_time": 4.5},
		{"id": 6,  "name": "Black Snake",     "category": "Real — Backyard",   "launch": "none",   "color": COL_SMOKE,  "settle_time": 4.5},
		{"id": 7,  "name": "Smoke Bomb",      "category": "Real — Backyard",   "launch": "mortar", "apex": 460.0, "hang": 0.10, "color": Color(0.55, 0.55, 0.55), "trail_kind": "smoke", "settle_time": 5.5},
		{"id": 8,  "name": "Crackle Ball",    "category": "Real — Backyard",   "launch": "mortar", "apex": 560.0, "hang": 0.12, "color": COL_WHITE, "settle_time": 4.5},
		{"id": 9,  "name": "Firecracker",     "category": "Real — Backyard",   "launch": "ground", "color": COL_WHITE,  "settle_time": 2.5, "shake": 4.0},
		{"id": 10, "name": "Small Mortar",    "category": "Real — Backyard",   "launch": "mortar", "apex": 540.0, "hang": 0.12, "color": COL_BLUE,  "settle_time": 4.0, "shake": 3.0},

		# --- Mid-tier cake / 200g ---
		{"id": 11, "name": "Repeater Cake",   "category": "Real — Cake",       "launch": "cake",   "color": COL_GOLD,   "settle_time": 8.5, "shots": 8, "spread": 520.0, "sub_id": 15, "palette": [COL_RED, COL_GREEN, COL_BLUE, COL_YELLOW, COL_PINK]},
		{"id": 12, "name": "Whistler Shell",  "category": "Real — Cake",       "launch": "mortar", "apex": 420.0, "hang": 0.25, "color": COL_SILVER, "settle_time": 4.5},
		{"id": 13, "name": "Comet",           "category": "Real — Cake",       "launch": "mortar", "apex": 380.0, "hang": 0.0,  "color": COL_GOLD,   "settle_time": 4.5},
		{"id": 14, "name": "Mine",            "category": "Real — Cake",       "launch": "ground", "color": COL_GOLD,   "settle_time": 4.5, "shake": 4.0},
		{"id": 15, "name": "Small Peony",     "category": "Real — Cake",       "launch": "mortar", "apex": 430.0, "hang": 0.15, "color": COL_RED,    "settle_time": 4.5, "shake": 3.0},
		{"id": 16, "name": "Small Chrysanthemum","category": "Real — Cake",    "launch": "mortar", "apex": 430.0, "hang": 0.15, "color": COL_ORANGE, "settle_time": 4.5, "shake": 3.0},
		{"id": 17, "name": "Strobe Shell",    "category": "Real — Cake",       "launch": "mortar", "apex": 440.0, "hang": 0.15, "color": COL_WHITE,  "settle_time": 5.5, "shake": 3.5},
		{"id": 18, "name": "Salute",          "category": "Real — Cake",       "launch": "mortar", "apex": 460.0, "hang": 0.15, "color": COL_WHITE,  "settle_time": 3.5, "shake": 8.0},
		{"id": 19, "name": "Glitter Mine",    "category": "Real — Cake",       "launch": "ground", "color": COL_GOLD,   "settle_time": 5.5},
		{"id": 20, "name": "Star Shell",      "category": "Real — Cake",       "launch": "mortar", "apex": 440.0, "hang": 0.20, "color": COL_YELLOW, "settle_time": 5.5, "shake": 2.0},

		# --- Pro aerial ---
		{"id": 21, "name": "Peony",           "category": "Real — Pro Aerial", "launch": "mortar", "apex": 280.0, "hang": 0.2, "color": COL_PINK,   "settle_time": 5.5, "shake": 5.0},
		{"id": 22, "name": "Chrysanthemum",   "category": "Real — Pro Aerial", "launch": "mortar", "apex": 280.0, "hang": 0.2, "color": COL_GOLD,   "settle_time": 6.0, "shake": 5.0},
		{"id": 23, "name": "Dahlia",          "category": "Real — Pro Aerial", "launch": "mortar", "apex": 280.0, "hang": 0.2, "color": COL_PURPLE, "settle_time": 6.5, "shake": 5.0},
		{"id": 24, "name": "Willow",          "category": "Real — Pro Aerial", "launch": "mortar", "apex": 260.0, "hang": 0.15,"color": COL_GOLD_WARM,"settle_time":8.0, "shake": 4.0},
		{"id": 25, "name": "Palm Tree",       "category": "Real — Pro Aerial", "launch": "mortar", "apex": 320.0, "hang": 0.05,"color": COL_GOLD,   "settle_time": 7.5, "shake": 4.0},
		{"id": 26, "name": "Crossette",       "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.15,"color": COL_CYAN,   "settle_time": 6.5, "shake": 4.5},
		{"id": 27, "name": "Brocade",         "category": "Real — Pro Aerial", "launch": "mortar", "apex": 280.0, "hang": 0.15,"color": COL_GOLD_WARM,"settle_time":8.0, "shake": 4.0},
		{"id": 28, "name": "Kamuro",          "category": "Real — Pro Aerial", "launch": "mortar", "apex": 260.0, "hang": 0.15,"color": COL_GOLD,   "settle_time": 8.0, "shake": 4.0},
		{"id": 29, "name": "Spider",          "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.15,"color": COL_GOLD,   "settle_time": 5.5, "shake": 4.5},
		{"id": 30, "name": "Horsetail",       "category": "Real — Pro Aerial", "launch": "mortar", "apex": 360.0, "hang": 0.0, "color": COL_GOLD,   "settle_time": 6.0, "shake": 3.5},
		{"id": 31, "name": "Ring Shell",      "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.15,"color": COL_WHITE,  "settle_time": 5.5, "shake": 4.5},
		{"id": 32, "name": "Heart Shell",     "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_RED,    "settle_time": 5.5, "shake": 4.5},
		{"id": 33, "name": "Smiley Face",     "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_YELLOW, "settle_time": 5.5, "shake": 4.5},
		{"id": 34, "name": "Star Pattern",    "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_CYAN,   "settle_time": 5.5, "shake": 4.5},
		{"id": 35, "name": "Multibreak",      "category": "Real — Pro Aerial", "launch": "mortar", "apex": 320.0, "hang": 0.15,"color": COL_BLUE,   "settle_time": 7.0, "shake": 5.5},
		{"id": 36, "name": "Color-Change Peony","category": "Real — Pro Aerial","launch": "mortar","apex": 280.0, "hang": 0.2, "color": COL_GREEN,  "settle_time": 6.0, "shake": 5.0},
		{"id": 37, "name": "Strobe Willow",   "category": "Real — Pro Aerial", "launch": "mortar", "apex": 260.0, "hang": 0.15,"color": COL_WHITE,  "settle_time": 8.0, "shake": 4.5},
		{"id": 38, "name": "Glitter Palm",    "category": "Real — Pro Aerial", "launch": "mortar", "apex": 320.0, "hang": 0.05,"color": COL_GOLD,   "settle_time": 7.5, "shake": 4.5},
		{"id": 39, "name": "Hummer",          "category": "Real — Pro Aerial", "launch": "mortar", "apex": 320.0, "hang": 0.15,"color": COL_ORANGE, "settle_time": 6.5, "shake": 4.0},
		{"id": 40, "name": "Pro Salute",      "category": "Real — Pro Aerial", "launch": "mortar", "apex": 300.0, "hang": 0.1, "color": COL_WHITE,  "settle_time": 5.0, "shake": 14.0},

		# --- Futuristic ---
		{"id": 41, "name": "Drone Swarm",     "category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_CYAN,   "settle_time": 7.5},
		{"id": 42, "name": "Quantum Bloom",   "category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_PURPLE, "settle_time": 7.0, "shake": 4.0},
		{"id": 43, "name": "Holo Letter",     "category": "Futuristic",        "launch": "mortar", "apex": 320.0, "hang": 0.2, "color": COL_CYAN,   "settle_time": 6.5, "shake": 3.0},
		{"id": 44, "name": "Nano Fractal",    "category": "Futuristic",        "launch": "mortar", "apex": 320.0, "hang": 0.15,"color": COL_PINK,   "settle_time": 8.0, "shake": 5.0},
		{"id": 45, "name": "Plasma Vortex",   "category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_BLUE,   "settle_time": 6.5, "shake": 4.0},
		{"id": 46, "name": "Black Hole Shell","category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_PURPLE, "settle_time": 7.5, "shake": 6.0},
		{"id": 47, "name": "Aurora Cascade",  "category": "Futuristic",        "launch": "mortar", "apex": 320.0, "hang": 0.15,"color": COL_AURORA_GREEN, "settle_time": 8.5},
		{"id": 48, "name": "Kinetic Wireframe","category": "Futuristic",       "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_CYAN,   "settle_time": 7.0, "shake": 4.5},
		{"id": 49, "name": "Gravity Loop",    "category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.2, "color": COL_ORANGE, "settle_time": 7.0},
		{"id": 50, "name": "Singularity",     "category": "Futuristic",        "launch": "mortar", "apex": 300.0, "hang": 0.3, "color": COL_WHITE,  "settle_time": 8.0, "shake": 10.0},

		# --- Stress test ---
		{"id": 51, "name": "Grand Finale Barrage","category": "Stress Test",   "launch": "barrage", "shots": 50,  "window": 10.0, "color": COL_WHITE, "settle_time": 18.0, "shake": 6.0},
		{"id": 52, "name": "Heavy Barrage",       "category": "Stress Test",   "launch": "barrage", "shots": 100, "window": 10.0, "color": COL_WHITE, "settle_time": 22.0, "shake": 6.0},
		{"id": 53, "name": "Inferno",             "category": "Stress Test",   "launch": "barrage", "shots": 200, "window": 8.0,  "color": COL_WHITE, "settle_time": 22.0, "shake": 6.0},
		{"id": 54, "name": "Endless Ramp",        "category": "Stress Test",   "launch": "endless", "interval": 0.5, "ramp_period": 5.0, "ramp_factor": 0.75, "color": COL_WHITE, "settle_time": 999.0},
	]

# --- Dispatch ----------------------------------------------------------

static func burst(id: int, field, pos: Vector2) -> void:
	match id:
		1:  _sparkler(field, pos)
		2:  _roman_candle(field, pos)
		3:  _bottle_rocket(field, pos)
		4:  _ground_spinner(field, pos)
		5:  _fountain(field, pos)
		6:  _black_snake(field, pos)
		7:  _smoke_bomb(field, pos)
		8:  _crackle_ball(field, pos)
		9:  _firecracker(field, pos)
		10: _small_mortar(field, pos)
		11: pass
		12: _whistler_shell(field, pos)
		13: _comet(field, pos)
		14: _mine(field, pos)
		15: _small_peony(field, pos)
		16: _small_chrysanthemum(field, pos)
		17: _strobe_shell(field, pos)
		18: _salute(field, pos)
		19: _glitter_mine(field, pos)
		20: _star_shell(field, pos)
		21: _peony(field, pos)
		22: _chrysanthemum(field, pos)
		23: _dahlia(field, pos)
		24: _willow(field, pos)
		25: _palm_tree(field, pos)
		26: _crossette(field, pos)
		27: _brocade(field, pos)
		28: _kamuro(field, pos)
		29: _spider(field, pos)
		30: _horsetail(field, pos)
		31: _ring_shell(field, pos)
		32: _heart_shell(field, pos)
		33: _smiley_face(field, pos)
		34: _star_pattern(field, pos)
		35: _multibreak(field, pos)
		36: _color_change_peony(field, pos)
		37: _strobe_willow(field, pos)
		38: _glitter_palm(field, pos)
		39: _hummer(field, pos)
		40: _pro_salute(field, pos)
		41: _drone_swarm(field, pos)
		42: _quantum_bloom(field, pos)
		43: _holo_letter(field, pos)
		44: _nano_fractal(field, pos)
		45: _plasma_vortex(field, pos)
		46: _black_hole_shell(field, pos)
		47: _aurora_cascade(field, pos)
		48: _kinetic_wireframe(field, pos)
		49: _gravity_loop(field, pos)
		50: _singularity(field, pos)

# --- Helper utilities --------------------------------------------------

static func _rand_unit(rng: RandomNumberGenerator) -> Vector2:
	var a = rng.randf() * TAU
	return Vector2(cos(a), sin(a))

static func _rand_sphere(rng: RandomNumberGenerator) -> Vector2:
	# Uniform random inside unit disk, not just edge
	var r = sqrt(rng.randf())
	return _rand_unit(rng) * r

static func _circle_burst(field, pos: Vector2, count: int, speed_min: float, speed_max: float,
		color: Color, life: float, gravity: float, drag: float, trail_len: int = 0, halo: float = 1.0, size: float = 2.0) -> void:
	var rng = field.rng
	for i in count:
		var a = rng.randf() * TAU
		var s = rng.randf_range(speed_min, speed_max)
		var v = Vector2(cos(a), sin(a)) * s
		field.spawn(pos, v, {
			"color": color, "size": size, "life": life,
			"gravity": gravity, "drag": drag,
			"trail_len": trail_len, "halo": halo,
			"trail_color": Color(color.r, color.g, color.b, 0.55),
		})

# --- BACKYARD / CONSUMER (1-10) ----------------------------------------

static func _sparkler(field, pos: Vector2) -> void:
	var rng = field.rng
	for i in 24:
		var delay = i * 0.12
		field._schedule(delay, func():
			for k in 12:
				var a = rng.randf_range(-PI, PI)
				var s = rng.randf_range(80, 240)
				field.spawn(pos + Vector2(0, -40), Vector2(cos(a), sin(a)) * s, {
					"color": Color(1.0, 0.9, 0.55), "size": 1.4, "life": 0.75,
					"gravity": 260.0, "drag": 0.25,
					"halo": 0.6, "fade": "flicker",
				})
		)

static func _roman_candle(field, pos: Vector2) -> void:
	var rng = field.rng
	var colors = [COL_RED, COL_GREEN, COL_BLUE, COL_YELLOW, COL_PURPLE, COL_PINK]
	var fire_one = func(col: Color):
		var apex_y = pos.y - rng.randf_range(260, 360)
		var start = pos
		var rise = start.y - apex_y
		var g = 220.0
		var v_y = -sqrt(2 * g * rise)
		var t_apex = -v_y / g
		field.particles.append({
			"pos": start, "vel": Vector2(rng.randf_range(-20, 20), v_y),
			"color": col, "size": 1.8, "life": t_apex + 0.05, "life_max": t_apex + 0.05,
			"gravity": g, "drag": 1.0, "fade": "none",
			"trail_len": 10, "trail": [],
			"trail_color": Color(col.r, col.g, col.b, 0.7),
			"halo": 1.1, "mode": "mortar",
			"strobe_rate": 0.0, "strobe_t": 0.0, "flicker_seed": 0.0,
			"meta": {
				"fw_id": -1,
				"apex_y": apex_y, "hang_time": 0.0, "post_apex": 0.0,
				"burst_queued": true,
				"custom_pop": {"kind": "roman_pop", "color": col},
			},
		})
	for i in 6:
		var delay = 0.25 + i * 0.55
		var col: Color = colors[i % colors.size()]
		field._schedule(delay, fire_one.bind(col))

static func _bottle_rocket(field, pos: Vector2) -> void:
	var rng = field.rng
	# Tiny pop at apex
	_circle_burst(field, pos, 20, 60, 120, COL_GOLD, 0.6, 160, 0.3, 0, 0.8, 1.4)
	# Little crackle
	for i in 6:
		field.spawn(pos, _rand_unit(rng) * rng.randf_range(30, 90), {
			"color": COL_WHITE, "size": 1.2, "life": 0.4,
			"gravity": 120.0, "drag": 0.2, "fade": "flicker",
		})

static func _ground_spinner(field, pos: Vector2) -> void:
	var rng = field.rng
	var emit = func(angle_base: float):
		for k in 4:
			var a = angle_base + k * (TAU * 0.25) + rng.randf_range(-0.2, 0.2)
			var s = rng.randf_range(140, 260)
			field.spawn(pos + Vector2(rng.randf_range(-6, 6), 0),
				Vector2(cos(a), -abs(sin(a)) * 0.4 - 0.3).normalized() * s, {
				"color": Color(1.0, 0.85 + rng.randf_range(-0.1, 0.1), 0.35), "size": 1.3, "life": 0.7,
				"gravity": 240.0, "drag": 0.2,
				"halo": 0.5, "fade": "flicker",
			})
	for t in 80:
		field._schedule(t * 0.03, emit.bind(t * 0.42))

static func _fountain(field, pos: Vector2) -> void:
	var rng = field.rng
	for t in 70:
		var delay = t * 0.04
		field._schedule(delay, func():
			for k in 6:
				var a = -PI * 0.5 + rng.randf_range(-0.35, 0.35)
				var s = rng.randf_range(340, 520)
				field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
					"color": Color(1.0, 0.88, 0.45), "size": 1.5, "life": 1.1,
					"gravity": 360.0, "drag": 0.25,
					"halo": 0.7, "fade": "flicker",
					"trail_len": 3,
					"trail_color": Color(1.0, 0.7, 0.25, 0.4),
				})
		)

static func _black_snake(field, pos: Vector2) -> void:
	var rng = field.rng
	# Real snakes leave a charred winding trail. We render this on the
	# non-additive smoke layer so the dark color reads correctly, plus a
	# single ember head moving in a sine-wave path along the ground.
	var path_dir := Vector2(1.0, 0.0).rotated(rng.randf_range(-0.4, 0.4))
	var emit_segment = func(idx: int):
		var t := float(idx)
		var head := pos + path_dir * (t * 6.0) + Vector2(0, sin(t * 0.4) * 18.0)
		# Charred snake body — dark grey on smoke layer
		field.spawn_smoke(head, Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)), {
			"color": Color(0.18, 0.14, 0.12), "size": 6.0, "life": 3.5,
			"gravity": -2.0, "drag": 0.6,
			"alpha_max": 0.85, "size_growth": 1.2,
		})
		# Soft grey smoke wisp rising from the path
		field.spawn_smoke(head, Vector2(rng.randf_range(-6, 6), -10.0 - rng.randf_range(0, 8)), {
			"color": Color(0.45, 0.42, 0.40), "size": 8.0, "life": 2.5,
			"gravity": -22.0, "drag": 0.5,
			"alpha_max": 0.55, "size_growth": 4.0,
		})
		# Tiny ember at head — additive layer for life
		field.spawn(head, Vector2(rng.randf_range(-12, 12), rng.randf_range(-25, -10)), {
			"color": Color(1.0, 0.55, 0.20), "size": 1.2, "life": 0.45,
			"gravity": 90.0, "drag": 0.4,
			"halo": 0.8, "fade": "flicker",
		})
	for i in 60:
		field._schedule(i * 0.06, emit_segment.bind(i))

static func _smoke_bomb(field, pos: Vector2) -> void:
	var rng = field.rng
	# Aerial smoke bomb: small colored "boom" of opaque smoke at apex.
	# Pick one bright hue so the cloud reads as a single color.
	var base_hue: float = rng.randf()
	var col := Color.from_hsv(base_hue, 0.78, 0.85)
	# Small initial pop — a few faster puffs in a ring
	for k in 12:
		var a = TAU * (float(k) / 12.0) + rng.randf_range(-0.15, 0.15)
		var s = rng.randf_range(60, 110)
		field.spawn_smoke(pos, Vector2(cos(a), sin(a) * 0.7) * s, {
			"color": col, "size": 11.0, "life": 2.8,
			"gravity": -10.0, "drag": 0.4,
			"alpha_max": 0.75, "size_growth": 18.0,
		})
	# Dense central cloud — slower puffs that linger
	var emit_puff = func():
		for k in 4:
			var a = rng.randf() * TAU
			var s = rng.randf_range(15, 55)
			field.spawn_smoke(pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8)),
				Vector2(cos(a), sin(a) * 0.5 - 0.2) * s, {
				"color": col, "size": 14.0, "life": 3.2,
				"gravity": -16.0, "drag": 0.42,
				"alpha_max": 0.65, "size_growth": 20.0,
			})
	for t in 12:
		field._schedule(t * 0.08, emit_puff)

static func _crackle_ball(field, pos: Vector2) -> void:
	var rng = field.rng
	for i in 30:
		var a = rng.randf() * TAU
		var s = rng.randf_range(90, 220)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_WHITE, "size": 1.4, "life": 1.3,
			"gravity": 220.0, "drag": 0.28,
			"halo": 0.7, "fade": "strobe",
			"strobe_rate": 32.0,
		})
	# Extra continuous crackle
	for t in 20:
		var delay = 0.15 + t * 0.06
		field._schedule(delay, func():
			for k in 4:
				field.spawn(pos + _rand_sphere(rng) * rng.randf_range(20, 80), _rand_unit(rng) * rng.randf_range(60, 160), {
					"color": COL_WHITE, "size": 1.3, "life": 0.45,
					"gravity": 180.0, "drag": 0.2,
					"halo": 0.8, "fade": "flicker",
				})
		)

static func _firecracker(field, pos: Vector2) -> void:
	var rng = field.rng
	# Lift the firecracker so the bang isn't half-buried, and add a fuse spark first.
	var fc_pos := pos + Vector2(0, -110)
	# Fuse spark traveling upward, leaving a trail
	var fuse_step = func(idx: int):
		field.spawn(pos + Vector2(rng.randf_range(-3, 3), -idx * 11.0),
			Vector2(rng.randf_range(-15, 15), -50.0), {
			"color": Color(1.0, 0.85, 0.35), "size": 1.1, "life": 0.35,
			"gravity": 80.0, "drag": 0.4,
			"halo": 0.6, "fade": "flicker",
		})
	for i in 10:
		field._schedule(i * 0.05, fuse_step.bind(i))
	# Bang after fuse
	field._schedule(0.55, func():
		# Sharp white flash
		field.spawn(fc_pos, Vector2.ZERO, {
			"color": COL_WHITE, "size": 18.0, "life": 0.15,
			"gravity": 0.0, "drag": 0.0, "halo": 3.5, "fade": "ease",
		})
		# Scattered sparks — short-lived, no falling underground
		for i in 24:
			var a = rng.randf() * TAU
			var s = rng.randf_range(120, 320)
			field.spawn(fc_pos, Vector2(cos(a), sin(a)) * s, {
				"color": Color(1.0, 0.78, 0.4), "size": 1.4, "life": 0.55,
				"gravity": 280.0, "drag": 0.25,
				"halo": 0.7, "fade": "flicker",
			})
		# Smoke puff on the smoke layer
		for k in 6:
			var a = rng.randf() * TAU
			field.spawn_smoke(fc_pos, Vector2(cos(a), sin(a)) * rng.randf_range(20, 60), {
				"color": Color(0.5, 0.5, 0.5), "size": 10.0, "life": 1.4,
				"gravity": -20.0, "drag": 0.4,
				"alpha_max": 0.55, "size_growth": 16.0,
			})
	)

static func _small_mortar(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 45, 140, 220, COL_BLUE, 1.4, 160, 0.35, 0, 1.0, 1.8)

# --- MID-TIER (11-20) --------------------------------------------------

static func _whistler_shell(field, pos: Vector2) -> void:
	var rng = field.rng
	# Small burst of silver + 4 whistling trailers that spin off
	_circle_burst(field, pos, 30, 100, 180, COL_SILVER, 1.0, 180, 0.3, 0, 0.9, 1.7)
	for i in 6:
		var a = rng.randf() * TAU
		var s = rng.randf_range(200, 320)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_WHITE, "size": 1.5, "life": 1.6,
			"gravity": 120.0, "drag": 0.15,
			"trail_len": 10, "halo": 1.0, "fade": "flicker",
			"trail_color": Color(1.0, 1.0, 1.0, 0.6),
		})

static func _comet(field, pos: Vector2) -> void:
	var rng = field.rng
	# Single bright streak with long glittery trail (main body) + faint halo sparks
	field.spawn(pos, Vector2(rng.randf_range(-30, 30), rng.randf_range(-40, -10)), {
		"color": COL_GOLD, "size": 3.4, "life": 2.4,
		"gravity": 60.0, "drag": 0.55,
		"trail_len": 28, "halo": 1.8, "fade": "ease",
		"trail_color": Color(1.0, 0.8, 0.35, 0.85),
	})
	for t in 18:
		var delay = t * 0.08
		field._schedule(delay, func():
			for k in 2:
				field.spawn(pos + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)),
					Vector2(rng.randf_range(-50, 50), rng.randf_range(-30, 40)), {
					"color": COL_GOLD_WARM, "size": 1.2, "life": 0.9,
					"gravity": 120.0, "drag": 0.2, "halo": 0.5, "fade": "flicker",
				})
		)

static func _mine(field, pos: Vector2) -> void:
	var rng = field.rng
	for i in 55:
		var a = -PI * 0.5 + rng.randf_range(-0.35, 0.35)
		var s = rng.randf_range(480, 720)
		field.spawn(pos + Vector2(rng.randf_range(-30, 30), 0), Vector2(cos(a), sin(a)) * s, {
			"color": COL_GOLD, "size": 1.8, "life": 1.6,
			"gravity": 260.0, "drag": 0.25,
			"trail_len": 5, "halo": 0.8, "fade": "flicker",
			"trail_color": Color(1.0, 0.7, 0.25, 0.55),
		})

static func _small_peony(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 65, 160, 230, COL_RED, 1.4, 140, 0.35, 0, 1.0, 1.9)

static func _small_chrysanthemum(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 65, 160, 230, COL_ORANGE, 1.5, 160, 0.35, 7, 1.0, 1.9)

static func _strobe_shell(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 60
	for i in count:
		var a = TAU * (float(i) / count) + rng.randf_range(-0.05, 0.05)
		var s = rng.randf_range(150, 220)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_WHITE, "size": 1.8, "life": 2.6,
			"gravity": 100.0, "drag": 0.35,
			"halo": 1.0, "fade": "strobe",
			"strobe_rate": 14.0 + rng.randf_range(-1.5, 1.5),
		})

static func _salute(field, pos: Vector2) -> void:
	var rng = field.rng
	# Sharp white flash
	field.spawn(pos, Vector2.ZERO, {
		"color": COL_WHITE, "size": 32.0, "life": 0.2,
		"gravity": 0.0, "drag": 0.0, "halo": 4.5, "fade": "ease",
	})
	_circle_burst(field, pos, 28, 260, 360, COL_WHITE, 0.6, 200, 0.2, 0, 1.5, 2.4)

static func _glitter_mine(field, pos: Vector2) -> void:
	var rng = field.rng
	for i in 45:
		var a = -PI * 0.5 + rng.randf_range(-0.35, 0.35)
		var s = rng.randf_range(420, 620)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": Color(1.0, 0.88, 0.45), "size": 1.6, "life": 2.2,
			"gravity": 220.0, "drag": 0.15,
			"trail_len": 4, "halo": 0.8, "fade": "shimmer",
			"trail_color": Color(1.0, 0.75, 0.3, 0.5),
		})

static func _star_shell(field, pos: Vector2) -> void:
	# Long-burning yellow stars
	_circle_burst(field, pos, 50, 120, 190, COL_YELLOW, 3.2, 60, 0.55, 0, 1.1, 2.1)

# --- PRO AERIAL (21-40) ------------------------------------------------

static func _peony(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 160, 220, 360, COL_PINK, 2.2, 130, 0.38, 0, 1.2, 2.6)

static func _chrysanthemum(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 160, 220, 360, COL_GOLD, 2.4, 150, 0.38, 12, 1.2, 2.6)

static func _dahlia(field, pos: Vector2) -> void:
	_circle_burst(field, pos, 60, 240, 360, COL_PURPLE, 2.8, 90, 0.5, 0, 1.4, 3.4)

static func _willow(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 100
	for i in count:
		var a = TAU * (float(i) / count) + rng.randf_range(-0.05, 0.05)
		var s = rng.randf_range(150, 260)
		# Steep bias: flatten so they fall long
		var v = Vector2(cos(a), sin(a)) * s
		v.y *= 0.4   # less vertical on initial — they'll droop naturally
		field.spawn(pos, v, {
			"color": COL_GOLD_WARM, "size": 1.6, "life": 3.4,
			"gravity": 80.0, "drag": 0.5,
			"trail_len": 16, "halo": 1.0, "fade": "flicker",
			"trail_color": Color(1.0, 0.65, 0.2, 0.7),
		})

static func _palm_tree(field, pos: Vector2) -> void:
	var rng = field.rng
	var trunk_dst = rng.randf_range(120, 180)
	var trunk_pos = pos + Vector2(0, -trunk_dst)
	var trunk_emit = func(idx: int):
		field.spawn(pos + Vector2(rng.randf_range(-6, 6), -idx * (trunk_dst / 14.0)),
			Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), {
			"color": COL_GOLD_WARM, "size": 2.6, "life": 2.6,
			"gravity": 60, "drag": 0.4,
			"trail_len": 8, "halo": 1.3, "fade": "ease",
			"trail_color": Color(1.0, 0.65, 0.25, 0.75),
		})
	for i in 14:
		field._schedule(i * 0.04, trunk_emit.bind(i))
	# Palm fronds burst at top
	var fronds = func():
		var count = 10
		for j in count:
			var base_a = -PI * 0.5
			var spread = PI * 0.85
			var a = base_a + lerp(-spread * 0.5, spread * 0.5, float(j) / (count - 1))
			var s = 250.0
			field.spawn(trunk_pos, Vector2(cos(a), sin(a)) * s, {
				"color": COL_GOLD_WARM, "size": 2.4, "life": 2.8,
				"gravity": 120.0, "drag": 0.3,
				"trail_len": 18, "halo": 1.3, "fade": "flicker",
				"trail_color": Color(1.0, 0.62, 0.22, 0.78),
			})
	field._schedule(0.4, fronds)

static func _crossette(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 22
	for i in count:
		var a = TAU * (float(i) / count)
		var s = rng.randf_range(180, 240)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_CYAN, "size": 2.2, "life": 1.0,
			"gravity": 110.0, "drag": 0.4,
			"trail_len": 8, "halo": 1.1, "fade": "linear",
			"trail_color": Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.65),
			"meta": {
				"on_death": {"kind": "split", "count": 4, "speed": 160.0, "life": 0.8, "color": COL_CYAN},
			},
		})

static func _brocade(field, pos: Vector2) -> void:
	var rng = field.rng
	_circle_burst(field, pos, 45, 130, 220, COL_GOLD_WARM, 3.6, 50, 0.55, 18, 1.0, 1.8)
	# extra shimmery core
	for i in 20:
		var a = rng.randf() * TAU
		var s = rng.randf_range(60, 160)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": Color(1.0, 0.7, 0.25), "size": 1.2, "life": 3.0,
			"gravity": 50.0, "drag": 0.5,
			"halo": 0.6, "fade": "shimmer",
		})

static func _kamuro(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 130
	for i in count:
		var a = rng.randf() * TAU
		var s = rng.randf_range(100, 220)
		var v = Vector2(cos(a), sin(a)) * s
		v.y *= 0.35
		field.spawn(pos, v, {
			"color": COL_GOLD, "size": 1.8, "life": 4.2,
			"gravity": 65.0, "drag": 0.5,
			"trail_len": 14, "halo": 1.1, "fade": "flicker",
			"trail_color": Color(1.0, 0.72, 0.3, 0.8),
		})

static func _spider(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 22
	for i in count:
		var a = TAU * (float(i) / count) + rng.randf_range(-0.02, 0.02)
		var s = 340.0
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_GOLD, "size": 1.5, "life": 1.4,
			"gravity": 30.0, "drag": 0.1,   # very little drag, straight lines
			"trail_len": 22, "halo": 0.9, "fade": "ease",
			"trail_color": Color(1.0, 0.85, 0.4, 0.8),
		})

static func _horsetail(field, pos: Vector2) -> void:
	var rng = field.rng
	# Falling burst — all initial velocities biased downward
	for i in 55:
		var a = rng.randf_range(PI * 0.15, PI * 0.85)  # lower semicircle with spread
		var s = rng.randf_range(150, 260)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_GOLD, "size": 1.8, "life": 2.4,
			"gravity": 120.0, "drag": 0.35,
			"trail_len": 12, "halo": 1.0, "fade": "flicker",
			"trail_color": Color(1.0, 0.75, 0.3, 0.75),
		})

static func _ring_shell(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 50
	for i in count:
		var a = TAU * (float(i) / count)
		var s = 260.0
		# Flat ring: only horizontal velocity initially
		field.spawn(pos, Vector2(cos(a) * s, sin(a) * s * 0.3), {
			"color": COL_WHITE, "size": 1.9, "life": 2.0,
			"gravity": 90.0, "drag": 0.35,
			"halo": 1.1, "fade": "ease",
			"trail_len": 6,
			"trail_color": Color(1.0, 1.0, 1.0, 0.5),
		})

static func _heart_shell(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 90
	for i in count:
		var t = TAU * (float(i) / count)
		# Parametric heart
		var hx = 16.0 * pow(sin(t), 3)
		var hy = -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		var v = Vector2(hx, hy).normalized() * Vector2(hx, hy).length() * 14.0
		field.spawn(pos, v, {
			"color": COL_RED, "size": 2.0, "life": 2.4,
			"gravity": 90.0, "drag": 0.5,
			"halo": 1.2, "fade": "ease",
			"trail_len": 6,
			"trail_color": Color(COL_RED.r, COL_RED.g, COL_RED.b, 0.5),
		})

static func _smiley_face(field, pos: Vector2) -> void:
	var rng = field.rng
	# Face outline (ring) + eyes + smile arc
	var ring_count = 40
	for i in ring_count:
		var a = TAU * (float(i) / ring_count)
		var dir = Vector2(cos(a), sin(a))
		field.spawn(pos, dir * 260.0, {
			"color": COL_YELLOW, "size": 1.9, "life": 2.4,
			"gravity": 80.0, "drag": 0.45, "halo": 1.1, "fade": "ease",
		})
	# Eyes — clustered
	for side in [-1.0, 1.0]:
		for k in 6:
			var a = rng.randf() * TAU
			var r = rng.randf() * 18.0
			var dir = Vector2(side * 100.0 + cos(a) * r, -90.0 + sin(a) * r).normalized()
			field.spawn(pos, dir * rng.randf_range(160, 200), {
				"color": COL_YELLOW, "size": 2.0, "life": 2.2,
				"gravity": 80.0, "drag": 0.45, "halo": 1.1, "fade": "ease",
			})
	# Smile arc (lower)
	for i in 14:
		var t = float(i) / 13.0
		var a = lerp(PI * 0.18, PI - PI * 0.18, t)
		var dir = Vector2(cos(a), sin(a) * 1.2).normalized()
		field.spawn(pos, dir * 230.0, {
			"color": COL_YELLOW, "size": 1.9, "life": 2.2,
			"gravity": 80.0, "drag": 0.45, "halo": 1.1, "fade": "ease",
		})

static func _star_pattern(field, pos: Vector2) -> void:
	# 5-point star: outer points + inner valleys, radial spokes contained on screen
	var rng = field.rng
	var outer_r := 240.0
	var inner_r := 95.0
	for i in 10:
		var a = -PI * 0.5 + TAU * (float(i) / 10.0)
		var r = outer_r if (i % 2 == 0) else inner_r
		# Particles travel from center to (r along direction) over ~1.0s
		# v0 ≈ r * (some factor accounting for drag) — use 1.6 with drag 0.4
		var dir = Vector2(cos(a), sin(a))
		var spoke_count := 7
		for k in spoke_count:
			var step = float(k) / float(spoke_count - 1)
			var speed = r * step * 2.2
			field.spawn(pos, dir * speed, {
				"color": COL_CYAN, "size": 2.0, "life": 2.4,
				"gravity": 60.0, "drag": 0.45, "halo": 1.1, "fade": "ease",
			})

static func _multibreak(field, pos: Vector2) -> void:
	var rng = field.rng
	_circle_burst(field, pos, 50, 180, 260, COL_BLUE, 1.6, 140, 0.4, 0, 1.1, 2.0)
	var sub_burst = func(off: Vector2, c: Color):
		_circle_burst(field, pos + off, 40, 160, 230, c, 1.4, 150, 0.4, 0, 1.1, 1.9)
	for j in 2:
		var off = Vector2(rng.randf_range(-180, 180), rng.randf_range(-120, 20))
		var c: Color = [COL_GREEN, COL_PINK, COL_YELLOW].pick_random()
		field._schedule(0.45 + j * 0.15, sub_burst.bind(off, c))

static func _color_change_peony(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 95
	for i in count:
		var a = TAU * (float(i) / count) + rng.randf_range(-0.04, 0.04)
		var s = rng.randf_range(200, 300)
		var v = Vector2(cos(a), sin(a)) * s
		field.spawn(pos, v, {
			"color": COL_GREEN, "size": 2.0, "life": 2.0,
			"gravity": 130.0, "drag": 0.4, "halo": 1.1, "fade": "linear",
			"meta": {"color_shift_to": COL_ORANGE, "color_shift_at": 0.55, "color_from": COL_GREEN},
		})
	# Apply color-shift via a follow-up scheduled pass (simple approximation: respawn shifted)
	field._schedule(0.9, func():
		_circle_burst(field, pos, 35, 120, 180, COL_ORANGE, 1.2, 130, 0.4, 0, 0.9, 1.6)
	)

static func _strobe_willow(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 55
	for i in count:
		var a = TAU * (float(i) / count)
		var s = rng.randf_range(150, 240)
		var v = Vector2(cos(a), sin(a)) * s
		v.y *= 0.4
		field.spawn(pos, v, {
			"color": COL_WHITE, "size": 1.6, "life": 3.6,
			"gravity": 75.0, "drag": 0.5,
			"trail_len": 12, "halo": 1.0, "fade": "strobe",
			"strobe_rate": 16.0,
			"trail_color": Color(1.0, 1.0, 1.0, 0.5),
		})

static func _glitter_palm(field, pos: Vector2) -> void:
	var rng = field.rng
	var trunk = rng.randf_range(130, 170)
	var top = pos + Vector2(0, -trunk)
	var trunk_emit = func(idx: int):
		field.spawn(pos + Vector2(rng.randf_range(-8, 8), -idx * (trunk / 12.0)),
			Vector2(rng.randf_range(-15, 15), rng.randf_range(-20, 10)), {
			"color": COL_GOLD, "size": 2.4, "life": 2.6,
			"gravity": 60.0, "drag": 0.42,
			"trail_len": 8, "halo": 1.3, "fade": "ease",
			"trail_color": Color(1.0, 0.75, 0.3, 0.75),
		})
	for i in 12:
		field._schedule(i * 0.04, trunk_emit.bind(i))
	var fronds = func():
		var count = 14
		for j in count:
			var a = -PI * 0.5 + lerp(-PI * 0.5, PI * 0.5, float(j) / (count - 1))
			var s = 240.0
			field.spawn(top, Vector2(cos(a), sin(a)) * s, {
				"color": COL_GOLD, "size": 2.0, "life": 2.4,
				"gravity": 90.0, "drag": 0.35,
				"trail_len": 14, "halo": 1.2, "fade": "shimmer",
				"trail_color": Color(1.0, 0.8, 0.35, 0.75),
			})
	field._schedule(0.4, fronds)

static func _hummer(field, pos: Vector2) -> void:
	var rng = field.rng
	var count = 9
	for i in count:
		var a = TAU * (float(i) / count)
		var s = rng.randf_range(120, 200)
		# Hummers: erratic spinning — we fake it with mild random acceleration via low drag + high gravity + heavy trail
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": COL_ORANGE, "size": 2.0, "life": 1.8,
			"gravity": 100.0, "drag": 0.12,
			"trail_len": 26, "halo": 1.0, "fade": "flicker",
			"trail_color": Color(1.0, 0.55, 0.15, 0.7),
		})

static func _pro_salute(field, pos: Vector2) -> void:
	var rng = field.rng
	# Enormous flash + shockwave ring + lingering glow
	field.spawn(pos, Vector2.ZERO, {
		"color": COL_WHITE, "size": 60.0, "life": 0.28,
		"gravity": 0.0, "drag": 0.0, "halo": 6.0, "fade": "ease",
	})
	# Shockwave ring
	var count = 90
	for i in count:
		var a = TAU * (float(i) / count)
		field.spawn(pos, Vector2(cos(a), sin(a)) * 520.0, {
			"color": COL_WHITE, "size": 2.4, "life": 0.7,
			"gravity": 120.0, "drag": 0.1, "halo": 1.4, "fade": "ease",
		})
	# Sparkle fallout
	for i in 60:
		var a = rng.randf() * TAU
		var s = rng.randf_range(120, 280)
		field.spawn(pos, Vector2(cos(a), sin(a)) * s, {
			"color": Color(1.0, 0.9, 0.6), "size": 1.4, "life": 1.6,
			"gravity": 220.0, "drag": 0.25, "halo": 0.7, "fade": "flicker",
		})

# --- FUTURISTIC (41-50) ------------------------------------------------

static func _drone_swarm(field, pos: Vector2) -> void:
	var rng = field.rng
	# Each drone is a small mortar that flies in formation, then bursts into its
	# own miniature firework. The swarm fans out from a V-formation.
	var count: int = 18
	var palette = [COL_CYAN, COL_PINK, COL_GREEN, COL_YELLOW, COL_PURPLE, COL_ORANGE]
	for i in count:
		var off_i: float = float(i) - float(count) * 0.5
		var spread_x: float = off_i * 60.0
		var spread_y: float = -absf(off_i) * 20.0   # V shape
		var target: Vector2 = pos + Vector2(spread_x, spread_y - rng.randf_range(60, 140))
		# Drone trail from center to target over ~0.9s
		var t_trav: float = 0.9
		var v0: Vector2 = (target - pos) / t_trav
		var col: Color = palette[i % palette.size()]
		# Spawn the drone as a colored mortar particle that bursts on death
		field.particles.append({
			"pos": pos, "vel": v0,
			"color": col, "size": 2.0,
			"life": t_trav, "life_max": t_trav,
			"gravity": 0.0, "drag": 1.0,
			"fade": "none",
			"trail_len": 18, "trail": [],
			"trail_color": Color(col.r, col.g, col.b, 0.8),
			"halo": 1.2, "mode": "drone",
			"strobe_rate": 0.0, "strobe_t": 0.0, "flicker_seed": rng.randf() * 5.0,
			"meta": {
				"on_death": {"kind": "drone_burst", "color": col},
			},
		})

static func _quantum_bloom(field, pos: Vector2) -> void:
	var rng = field.rng
	# Burst, then at 0.4s each particle spawns "clones" nearby (teleport look)
	var count = 30
	for i in count:
		var a = TAU * (float(i) / count)
		var s = rng.randf_range(150, 240)
		var v = Vector2(cos(a), sin(a)) * s
		field.spawn(pos, v, {
			"color": COL_PURPLE, "size": 2.0, "life": 2.2,
			"gravity": 80.0, "drag": 0.4, "halo": 1.2, "fade": "strobe",
			"strobe_rate": 24.0,
			"trail_len": 4,
			"trail_color": Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.45),
		})
	# Clone teleports
	for t in 4:
		field._schedule(0.3 + t * 0.3, func():
			for k in 25:
				var angle = rng.randf() * TAU
				var r = rng.randf_range(60, 220)
				var off = Vector2(cos(angle), sin(angle)) * r
				field.spawn(pos + off, Vector2.ZERO, {
					"color": COL_PURPLE, "size": 2.4, "life": 0.4,
					"gravity": 0, "drag": 0, "halo": 1.4, "fade": "ease",
				})
		)

static func _holo_letter(field, pos: Vector2) -> void:
	# Particle-formed letter "A" — particles travel from center to formation
	# points, hover briefly, then scatter outward.
	var rng = field.rng
	var points = _letter_A_points()
	var scale := 280.0
	for pt in points:
		var local = (pt - Vector2(0.5, 0.5)) * scale
		# Each formation point: spawn 3 particles densely so the letter reads thick.
		# v = local * 7 with drag 0.001 → particles arrive at target then stop dead.
		for k in 3:
			var jitter = Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			var v = (local + jitter) * 7.0
			field.spawn(pos, v, {
				"color": COL_CYAN, "size": 2.6, "life": 3.2,
				"gravity": 0.0, "drag": 0.001,
				"halo": 1.5, "fade": "ease",
			})
	# After the letter forms, scatter all particles outward
	var scatter = func():
		for pt in points:
			var local = (pt - Vector2(0.5, 0.5)) * scale
			var target = pos + local
			for k in 3:
				var v = _rand_unit(rng) * rng.randf_range(160, 280)
				field.spawn(target, v, {
					"color": COL_CYAN, "size": 1.8, "life": 1.2,
					"gravity": 140.0, "drag": 0.3, "halo": 1.0, "fade": "flicker",
				})
	field._schedule(2.0, scatter)

static func _letter_A_points() -> Array:
	# Hand-picked points along letter A
	var pts: Array = []
	# Left diagonal
	for i in 12:
		var t = float(i) / 11.0
		pts.append(Vector2(0.1 + t * 0.4, 1.0 - t * 0.95))
	# Right diagonal
	for i in 12:
		var t = float(i) / 11.0
		pts.append(Vector2(0.9 - t * 0.4, 1.0 - t * 0.95))
	# Crossbar
	for i in 7:
		var t = float(i) / 6.0
		pts.append(Vector2(0.3 + t * 0.4, 0.55))
	return pts

static func _nano_fractal(field, pos: Vector2) -> void:
	# Recurses 2 levels (down from 3) and child count drops at each level
	# to keep the final wave from blowing the particle budget.
	_fractal_burst(field, pos, 2, 200.0, COL_PINK, 6)

static func _fractal_burst(field, pos: Vector2, depth: int, speed: float, color: Color, count: int) -> void:
	var rng = field.rng
	var spawn_child = func(child_pos: Vector2, child_depth: int, child_speed: float, child_color: Color, child_count: int):
		_fractal_burst(field, child_pos, child_depth, child_speed, child_color, child_count)
	for i in count:
		var a = TAU * (float(i) / count) + rng.randf_range(-0.1, 0.1)
		var v = Vector2(cos(a), sin(a)) * speed
		field.spawn(pos, v, {
			"color": color, "size": 2.0 + depth * 0.3, "life": 1.0,
			"gravity": 90.0, "drag": 0.4, "halo": 1.1, "fade": "ease",
			"trail_len": 6,
			"trail_color": Color(color.r, color.g, color.b, 0.65),
		})
		if depth > 0:
			var child_pos = pos + v * 0.7
			# Children: half the count, smaller speed
			field._schedule(0.55, spawn_child.bind(child_pos, depth - 1, speed * 0.55, color, max(3, count - 2)))

static func _plasma_vortex(field, pos: Vector2) -> void:
	var emit_ring = func(t_idx: int):
		for k in 4:
			var angle = float(t_idx) * 0.45 + k * (TAU * 0.25)
			var r = 40.0 + float(t_idx) * 7.0
			var p_start = pos + Vector2(cos(angle), sin(angle)) * r
			var tangent = Vector2(-sin(angle), cos(angle))
			var v = tangent * 180.0 + (pos - p_start).normalized() * 50.0
			field.spawn(p_start, v, {
				"color": COL_BLUE, "size": 1.8, "life": 1.6,
				"gravity": -30.0, "drag": 0.5, "halo": 1.2, "fade": "shimmer",
				"trail_len": 10,
				"trail_color": Color(0.4, 0.65, 1.0, 0.55),
			})
	for t in 40:
		field._schedule(t * 0.035, emit_ring.bind(t))

static func _black_hole_shell(field, pos: Vector2) -> void:
	var rng = field.rng
	# Phase 1: particles spawn at outer ring, move inward (implosion)
	var count = 50
	for i in count:
		var a = TAU * (float(i) / count)
		var r = 220.0
		var start = pos + Vector2(cos(a), sin(a)) * r
		var v = (pos - start).normalized() * 280.0
		field.spawn(start, v, {
			"color": COL_PURPLE, "size": 1.8, "life": 0.7,
			"gravity": 0.0, "drag": 1.0,  # no slowing — direct travel
			"halo": 1.0, "fade": "linear",
			"trail_len": 10,
			"trail_color": Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.55),
		})
	# Phase 2: explosion outward
	field._schedule(0.75, func():
		field.spawn(pos, Vector2.ZERO, {
			"color": COL_WHITE, "size": 24.0, "life": 0.25,
			"gravity": 0.0, "drag": 0.0, "halo": 3.5, "fade": "ease",
		})
		_circle_burst(field, pos, 80, 260, 420, COL_PURPLE, 1.8, 130, 0.35, 10, 1.2, 2.2)
	)

static func _aurora_cascade(field, pos: Vector2) -> void:
	var rng = field.rng
	var emit_dot = func(x_off: float, y_off: float, ribbon_idx: int, col: Color):
		field.spawn(pos + Vector2(x_off, y_off + sin(x_off * 0.02 + ribbon_idx) * 18.0),
			Vector2(rng.randf_range(-8, 8), rng.randf_range(-5, 5)), {
			"color": col, "size": 3.2, "life": 2.2,
			"gravity": 8.0, "drag": 0.55, "halo": 2.2, "fade": "shimmer",
		})
	for ribbon in 3:
		var y_off = float(ribbon - 1) * 40.0
		var col: Color = [COL_AURORA_GREEN, COL_AURORA_PURPLE, COL_CYAN][ribbon]
		for t in 70:
			var x_off = float(t - 35) * 26.0
			var delay = 0.02 * t + ribbon * 0.2
			field._schedule(delay, emit_dot.bind(x_off, y_off, ribbon, col))

static func _kinetic_wireframe(field, pos: Vector2) -> void:
	var rng = field.rng
	# Cube wireframe: 8 corners + 12 edge-traversing particles
	var s = 80.0
	var corners = [
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s),
		Vector2(-s * 0.6, -s * 0.6 - 30), Vector2(s * 0.6, -s * 0.6 - 30),
		Vector2(s * 0.6, s * 0.6 - 30), Vector2(-s * 0.6, s * 0.6 - 30),
	]
	# Hovering dots at corners
	for c in corners:
		field.spawn(pos + c, Vector2.ZERO, {
			"color": COL_CYAN, "size": 3.2, "life": 2.6,
			"gravity": 0.0, "drag": 0.001, "halo": 1.4, "fade": "ease",
		})
	# Edge walkers — particles traveling along edges
	var edges = [[0,1],[1,2],[2,3],[3,0], [4,5],[5,6],[6,7],[7,4], [0,4],[1,5],[2,6],[3,7]]
	var walker = func(a_idx: int, b_idx: int):
		var a = corners[a_idx]
		var b = corners[b_idx]
		var dir = (b - a).normalized()
		var p_start = pos + a + dir * 8.0
		field.spawn(p_start, dir * 120.0, {
			"color": COL_CYAN, "size": 1.6, "life": 1.4,
			"gravity": 0.0, "drag": 0.9, "halo": 0.9, "fade": "flicker",
			"trail_len": 5,
			"trail_color": Color(0.35, 1.0, 0.95, 0.55),
		})
	for e in edges:
		for t_idx in 6:
			field._schedule(t_idx * 0.12, walker.bind(e[0], e[1]))
	# Shatter at end
	var shatter = func():
		for c in corners:
			_circle_burst(field, pos + c, 14, 120, 200, COL_CYAN, 1.0, 150, 0.35, 0, 1.0, 1.4)
	field._schedule(2.4, shatter)

static func _gravity_loop(field, pos: Vector2) -> void:
	var rng = field.rng
	# Particles spawned with tangential velocities that trace figure-8 via prescribed paths
	# We approximate by having two orbital rings with alternating rotation
	var count = 24
	for i in count:
		var t_phase = TAU * (float(i) / count)
		var dir_flip = 1.0 if (i % 2 == 0) else -1.0
		var speed = 240.0
		# Position around a focus; velocity tangential; slight cross-coupling for 8-shape
		var start = pos + Vector2(cos(t_phase), sin(t_phase)) * 30.0
		var tangent = Vector2(-sin(t_phase), cos(t_phase)) * speed * dir_flip
		field.spawn(start, tangent, {
			"color": COL_ORANGE, "size": 2.0, "life": 3.0,
			"gravity": 0.0, "drag": 0.9,   # very mild drag
			"trail_len": 22, "halo": 1.1, "fade": "ease",
			"trail_color": Color(COL_ORANGE.r, COL_ORANGE.g, COL_ORANGE.b, 0.7),
		})

static func _singularity(field, pos: Vector2) -> void:
	var rng = field.rng
	# Phase 1: radial inward collapse from random points
	for i in 80:
		var a = rng.randf() * TAU
		var r = rng.randf_range(280, 400)
		var start = pos + Vector2(cos(a), sin(a)) * r
		var v = (pos - start).normalized() * 420.0
		field.spawn(start, v, {
			"color": COL_WHITE, "size": 1.6, "life": 0.9,
			"gravity": 0.0, "drag": 1.0, "halo": 0.9, "fade": "linear",
			"trail_len": 14,
			"trail_color": Color(1.0, 1.0, 1.0, 0.6),
		})
	# Phase 2: massive flash
	field._schedule(0.95, func():
		field.spawn(pos, Vector2.ZERO, {
			"color": COL_WHITE, "size": 70.0, "life": 0.35,
			"gravity": 0.0, "drag": 0.0, "halo": 7.0, "fade": "ease",
		})
	)
	# Phase 3: huge outward shell, multi-color (trimmed for perf — one combined ring + scattered colors)
	var grand_shell = func():
		var colors = [COL_RED, COL_GREEN, COL_BLUE, COL_YELLOW, COL_CYAN, COL_PINK, COL_PURPLE]
		# One dense ring (140 white particles, no trails) for shockwave
		_circle_burst(field, pos, 140, 280, 420, COL_WHITE, 1.4, 110, 0.3, 0, 1.3, 2.2)
		# Scattered color stars — one pass per color, modest count, no trails
		for c in colors:
			_circle_burst(field, pos, 18, 180, 360, c, 2.0, 100, 0.35, 0, 1.2, 2.0)
	field._schedule(1.1, grand_shell)
