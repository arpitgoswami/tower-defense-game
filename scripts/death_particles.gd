extends CPUParticles2D
## One-shot goo burst. Set `color` after instancing.


func _ready() -> void:
	emitting = true
	get_tree().create_timer(lifetime + 0.4).timeout.connect(queue_free)
