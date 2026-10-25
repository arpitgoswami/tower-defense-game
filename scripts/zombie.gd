class_name Zombie
extends Node2D
## One enemy. Walks to the tower, attacks it, can be knocked back. Stats come from TYPE_DATA x wave scaling.

signal damaged(amount: float, crit: bool, pos: Vector2)
signal died(zombie: Zombie)

enum Kind { NORMAL, FAST, TANK, BOSS }

const KB_DAMP := 8.0  # knockback velocity decay; displacement == knockback * resist

## hp / speed(px/s) / damage(per hit) / coins / attack_speed(anim scale) / scale / attack_distance / kb_resist
const TYPE_DATA: Dictionary = {
	Kind.NORMAL: {"frames": "res://assets/frames/zombie_normal_frames.tres", "hp": 22.0, "speed": 38.0, "damage": 6.0,
		"coins": 3, "attack_speed": 1.0, "scale": 2.0, "attack_distance": 50.0, "kb_resist": 1.0, "color": Color(0.45, 0.75, 0.35)},
	Kind.FAST: {"frames": "res://assets/frames/zombie_fast_frames.tres", "hp": 13.0, "speed": 78.0, "damage": 4.0,
		"coins": 3, "attack_speed": 1.4, "scale": 2.0, "attack_distance": 50.0, "kb_resist": 1.1, "color": Color(0.7, 0.8, 0.4)},
	Kind.TANK: {"frames": "res://assets/frames/zombie_tank_frames.tres", "hp": 95.0, "speed": 24.0, "damage": 14.0,
		"coins": 7, "attack_speed": 0.8, "scale": 2.0, "attack_distance": 56.0, "kb_resist": 0.5, "color": Color(0.3, 0.55, 0.35)},
	Kind.BOSS: {"frames": "res://assets/frames/zombie_boss_frames.tres", "hp": 420.0, "speed": 20.0, "damage": 32.0,
		"coins": 60, "attack_speed": 0.75, "scale": 2.0, "attack_distance": 66.0, "kb_resist": 0.2, "color": Color(0.6, 0.35, 0.65)},
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow

var kind: int = Kind.NORMAL
var max_hp: float = 20.0
var hp: float = 20.0
var speed: float = 40.0
var damage: float = 5.0
var coin_value: int = 1
var attack_distance: float = 50.0
var kb_resist: float = 1.0
var blood_color: Color = Color.WHITE
var dead: bool = false

var _target: Node2D
var _kb_vel: Vector2 = Vector2.ZERO
var _attacking: bool = false
var _body_h: float = 48.0
var _attack_speed: float = 1.0
var _walk_scale: float = 1.0
var _flash_tween: Tween


func _ready() -> void:
	add_to_group("zombies")
	sprite.frame_changed.connect(_on_frame_changed)


func setup(p_kind: int, target: Node2D, hp_mult: float, dmg_mult: float, speed_mult: float, coin_mult: float) -> void:
	kind = p_kind
	_target = target
	var data: Dictionary = TYPE_DATA[kind]
	max_hp = float(data["hp"]) * hp_mult
	hp = max_hp
	speed = float(data["speed"]) * speed_mult
	damage = float(data["damage"]) * dmg_mult
	coin_value = maxi(1, int(round(float(data["coins"]) * coin_mult)))
	attack_distance = float(data["attack_distance"]) + randf_range(0.0, 14.0)
	kb_resist = float(data["kb_resist"])
	blood_color = data["color"]
	_attack_speed = float(data["attack_speed"])
	sprite.sprite_frames = load(data["frames"]) as SpriteFrames
	var frame_h := float(sprite.sprite_frames.get_frame_texture("walk", 0).get_height())
	var sc := float(data["scale"])
	sprite.scale = Vector2(sc, sc)
	sprite.offset = Vector2(0.0, -frame_h * 0.5 + 2.0)
	_body_h = frame_h * sc
	shadow.scale = Vector2(sc, sc) * (frame_h / 24.0)
	_walk_scale = clampf(speed / 40.0, 0.7, 1.8) * randf_range(0.9, 1.1)
	sprite.speed_scale = _walk_scale
	sprite.play("walk")
	sprite.frame = randi() % 4


func hit_point() -> Vector2:
	return global_position + Vector2(0.0, -_body_h * 0.5)


func _process(delta: float) -> void:
	if dead or _target == null:
		return
	var to := _target.global_position - global_position
	var dist := to.length()
	var move := Vector2.ZERO
	if dist > attack_distance:
		move = to / maxf(dist, 0.001) * speed
		if _attacking:
			_set_attacking(false)
	elif not _attacking:
		_set_attacking(true)
	position += (move + _kb_vel) * delta
	_kb_vel *= exp(-KB_DAMP * delta)


func _set_attacking(value: bool) -> void:
	_attacking = value
	if value:
		sprite.speed_scale = _attack_speed
		sprite.play("attack")
	else:
		sprite.speed_scale = _walk_scale
		sprite.play("walk")


func _on_frame_changed() -> void:
	# the strike lands on frame 2 of the attack animation
	if _attacking and not dead and sprite.animation == &"attack" and sprite.frame == 2:
		GameState.damage_tower(damage)
		AudioManager.play("hit", 0.1, -12.0)


func take_damage(amount: float, crit: bool, knockback: float) -> void:
	if dead:
		return
	hp -= amount
	damaged.emit(amount, crit, global_position + Vector2(0.0, -_body_h))
	var away := (global_position - _target.global_position).normalized() if _target else Vector2.DOWN
	_kb_vel += away * knockback * KB_DAMP * kb_resist
	_flash()
	queue_redraw()
	if hp <= 0.0:
		_die()


func _flash() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	mat.set_shader_parameter("flash", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.14)


func _die() -> void:
	dead = true
	remove_from_group("zombies")
	died.emit(self)
	AudioManager.play("zombie_death", 0.12)
	queue_redraw()
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "modulate:a", 0.0, 0.22)
	t.tween_property(sprite, "scale", Vector2(sprite.scale.x * 1.25, 0.2), 0.22)
	t.tween_property(shadow, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(queue_free)


func _draw() -> void:
	if dead or hp >= max_hp:
		return
	var w := maxf(24.0, _body_h * 0.6)
	var y := -_body_h - 8.0
	draw_rect(Rect2(-w * 0.5 - 1.0, y - 1.0, w + 2.0, 6.0), Color(0.1, 0.05, 0.12, 0.9))
	draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color(0.85, 0.2, 0.2))
