extends Node2D
## Draws the wizard's attack range on the ground.

@export var radius: float = 175.0
@export var fill_color: Color = Color(0.5, 0.7, 1.0, 0.07)
@export var line_color: Color = Color(0.7, 0.85, 1.0, 0.55)
@export var dash_count: int = 48


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	var step := TAU / float(dash_count)
	for i in range(0, dash_count, 2):
		draw_arc(Vector2.ZERO, radius, i * step, (i + 1) * step, 6, line_color, 2.0)


func set_radius(r: float) -> void:
	radius = r
	queue_redraw()
