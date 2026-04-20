extends Node2D
class_name SmokeLayer
## Non-additive sub-layer for smoke / snake / opaque particles.
## Reads from field.smoke_particles and renders with normal alpha blending.

var field: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if field == null:
		return
	for p in field.smoke_particles:
		var life_t: float = clamp(p.life / p.life_max, 0.0, 1.0)
		var alpha: float = life_t * p.get("alpha_max", 0.5)
		var c: Color = p.color
		# Soft cloud — stack two circles
		draw_circle(p.pos, p.size * 1.4, Color(c.r, c.g, c.b, alpha * 0.5))
		draw_circle(p.pos, p.size, Color(c.r, c.g, c.b, alpha))
