extends AnimatedSprite2D
## One-shot bolt impact burst.


func _ready() -> void:
	animation_finished.connect(queue_free)
	play("hit")
