extends Node2D
## Floating combat text. Call show_value() right after adding to the tree.

@export var rise: float = 68.0
@export var duration: float = 0.75
@export var normal_color: Color = Color(1, 1, 1)
@export var crit_color: Color = Color(1, 0.8, 0.2)

@onready var label: Label = $Label


func show_value(amount: float, crit: bool) -> void:
	label.text = "%d%s" % [int(round(amount)), "!" if crit else ""]
	label.add_theme_color_override("font_color", crit_color if crit else normal_color)
	scale = Vector2.ONE * (1.6 if crit else 1.0)
	position.x += randf_range(-20.0, 20.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:y", position.y - rise, duration).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	t.chain().tween_callback(queue_free)
