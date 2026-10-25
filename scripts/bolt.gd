class_name Bolt
extends Node2D
## Homing magic bolt. Applies damage + knockback on arrival and spawns an impact effect.

@export var hit_radius: float = 10.0
@export var impact_scene: PackedScene

var _target: Zombie
var _damage: float = 10.0
var _crit: bool = false
var _knockback: float = 40.0
var _speed: float = 500.0
var _dir: Vector2 = Vector2.RIGHT
var _orphan_life: float = 0.6


func launch(target: Zombie, damage: float, crit: bool, knockback: float, speed: float) -> void:
	_target = target
	_damage = damage
	_crit = crit
	_knockback = knockback
	_speed = speed
	_dir = (target.hit_point() - global_position).normalized()
	rotation = _dir.angle()
	if crit:
		scale = Vector2(1.4, 1.4)


func _process(delta: float) -> void:
	var step := _speed * delta
	if _target == null or not is_instance_valid(_target) or _target.dead:
		_orphan_life -= delta  # target died mid-flight: fly on briefly, then fizzle
		global_position += _dir * step
		if _orphan_life <= 0.0:
			queue_free()
		return
	var to := _target.hit_point() - global_position
	if to.length() <= hit_radius + step:
		_hit()
		return
	_dir = to.normalized()
	global_position += _dir * step
	rotation = _dir.angle()


func _hit() -> void:
	_target.take_damage(_damage, _crit, _knockback)
	if impact_scene != null:
		var fx := impact_scene.instantiate() as Node2D
		get_parent().add_child(fx)
		fx.global_position = global_position
		if _crit:
			fx.scale *= 1.5
	AudioManager.play("hit", 0.15, -3.0)
	queue_free()
