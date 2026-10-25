class_name Wizard
extends Node2D
## Stands on the tower, auto-targets the nearest zombie in range and casts bolts.

signal cast(target: Node2D)

@export var attack_range: float = 175.0
@export var shots_per_second: float = 1.6
@export var bolt_scene: PackedScene
@export var bolt_speed: float = 520.0
@export var muzzle_offset: Vector2 = Vector2(12, -38)

@onready var sprite: AnimatedSprite2D = $Sprite

var _cooldown: float = 0.5


func _ready() -> void:
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	if not GameState.run_active:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := find_target()
	if target == null:
		return
	_cooldown = 1.0 / shots_per_second
	_cast_at(target)


func origin() -> Vector2:
	return get_parent().global_position  # tower base = centre of the range circle


func find_target() -> Zombie:
	var best: Zombie = null
	var best_d := attack_range * attack_range
	var o := origin()
	for n in get_tree().get_nodes_in_group("zombies"):
		var z := n as Zombie
		if z == null or z.dead:
			continue
		var d := o.distance_squared_to(z.global_position)
		if d <= best_d:
			best_d = d
			best = z
	return best


func _cast_at(target: Zombie) -> void:
	var facing_left := target.global_position.x < global_position.x
	sprite.flip_h = facing_left
	sprite.play("cast")
	var parent := get_tree().get_first_node_in_group("effects")
	if parent == null or bolt_scene == null:
		return
	var bolt := bolt_scene.instantiate() as Bolt
	parent.add_child(bolt)
	var off := Vector2(-muzzle_offset.x if facing_left else muzzle_offset.x, muzzle_offset.y)
	bolt.global_position = global_position + off
	var crit := randf() < GameState.crit_chance()
	var dmg := GameState.damage() * GameState.damage_multiplier() * randf_range(0.92, 1.08)
	if crit:
		dmg *= GameState.crit_multiplier
	bolt.launch(target, dmg, crit, GameState.knockback(), bolt_speed)
	AudioManager.play("cast", 0.08)
	cast.emit(target)


func _on_animation_finished() -> void:
	if sprite.animation == &"cast":
		sprite.play("idle")
