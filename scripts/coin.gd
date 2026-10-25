class_name Coin
extends Node2D
## Pops out of a dead zombie, rests briefly, then flies to the tower and is collected.

enum Phase { POP, WAIT, FLY }

@export var collect_delay: float = 0.6
@export var gravity: float = 700.0
@export var fly_accel: float = 1600.0

@onready var sprite: AnimatedSprite2D = $Sprite

var value: int = 1
var _tower: Node2D
var _phase: int = Phase.POP
var _vel: Vector2 = Vector2.ZERO
var _ground_y: float = 0.0
var _age: float = 0.0
var _fly_speed: float = 120.0


func _ready() -> void:
	sprite.play("spin")
	sprite.frame = randi() % 4


func setup(p_value: int, tower: Node2D) -> void:
	value = p_value
	_tower = tower
	_vel = Vector2(randf_range(-70.0, 70.0), randf_range(-170.0, -110.0))
	_ground_y = global_position.y + randf_range(-6.0, 14.0)


func _process(delta: float) -> void:
	_age += delta
	match _phase:
		Phase.POP:
			global_position += _vel * delta
			_vel.y += gravity * delta
			if _vel.y > 0.0 and global_position.y >= _ground_y:
				global_position.y = _ground_y
				_phase = Phase.WAIT
		Phase.WAIT:
			if _age >= collect_delay:
				_phase = Phase.FLY
		Phase.FLY:
			if _tower == null:
				queue_free()
				return
			var goal := _tower.global_position + Vector2(0.0, -50.0)
			_fly_speed += fly_accel * delta
			var to := goal - global_position
			var step := _fly_speed * delta
			if to.length() <= step + 6.0:
				_collect()
				return
			global_position += to.normalized() * step
			scale = Vector2.ONE * clampf(to.length() / 90.0, 0.5, 1.0)


func _collect() -> void:
	GameState.add_coins(value)
	AudioManager.play("coin", 0.12, -6.0)
	queue_free()
