extends Node2D
## Starfield + faint city silhouette. Procedural, rendered once via _draw.

const SCREEN := Vector2(1920, 1080)
const STAR_COUNT := 260
const SKYLINE_Y := 940.0

var _stars: Array = []
var _skyline: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 997
	for i in STAR_COUNT:
		_stars.append({
			"pos": Vector2(rng.randf() * SCREEN.x, rng.randf() * (SKYLINE_Y - 30)),
			"size": rng.randf_range(0.6, 1.8),
			"twinkle_speed": rng.randf_range(0.4, 1.8),
			"twinkle_phase": rng.randf() * TAU,
			"base": rng.randf_range(0.35, 0.85),
		})
	# Procedural skyline silhouette — jagged buildings
	_skyline.append(Vector2(0, SCREEN.y))
	var x := 0.0
	var h_last := 60.0
	while x < SCREEN.x:
		var w := rng.randf_range(24.0, 90.0)
		var h := rng.randf_range(30.0, 130.0)
		_skyline.append(Vector2(x, SKYLINE_Y - h_last))
		_skyline.append(Vector2(x, SKYLINE_Y - h))
		h_last = h
		x += w
	_skyline.append(Vector2(SCREEN.x, SKYLINE_Y - h_last))
	_skyline.append(Vector2(SCREEN.x, SCREEN.y))

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Sky gradient
	var top_color := Color(0.015, 0.015, 0.04)
	var horizon_color := Color(0.05, 0.03, 0.08)
	var steps := 20
	for s in steps:
		var t := float(s) / float(steps)
		var c := top_color.lerp(horizon_color, t)
		var y := t * SKYLINE_Y
		var h := SKYLINE_Y / float(steps) + 1.0
		draw_rect(Rect2(0, y, SCREEN.x, h), c, true)

	# Stars with twinkle
	var now := Time.get_ticks_msec() / 1000.0
	for s in _stars:
		var twinkle := 0.7 + 0.3 * sin(now * s.twinkle_speed + s.twinkle_phase)
		var alpha = clamp(s.base * twinkle, 0.0, 1.0)
		draw_circle(s.pos, s.size, Color(1.0, 1.0, 1.0, alpha))

	# City skyline
	draw_colored_polygon(_skyline, Color(0.02, 0.02, 0.04))
	# Window lights — random points above skyline
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	for i in 80:
		var wx = rng.randf() * SCREEN.x
		var wy = SKYLINE_Y - rng.randf_range(20, 100)
		var a := 0.18 + 0.12 * sin(now * 0.5 + i)
		draw_rect(Rect2(wx, wy, 2, 3), Color(1.0, 0.85, 0.4, a), true)
