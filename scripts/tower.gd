extends Node2D
## Tower visuals: hit tint + crumble when destroyed.

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	GameState.tower_hit.connect(_on_hit)
	GameState.tower_destroyed.connect(_on_destroyed)


func _on_hit(_amount: float) -> void:
	sprite.modulate = Color(1.0, 0.45, 0.45)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.18)


func _on_destroyed() -> void:
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(0.25, 0.2, 0.2), 0.8)
