extends Node2D
## Game.tscn root: wires spawner, effects, HUD and game-over flow together.

@export var tree_textures: Array[Texture2D] = []
@export var tree_count: int = 30
@export var tree_ring_radius: Vector2 = Vector2(330.0, 170.0)
@export var damage_number_scene: PackedScene
@export var coin_scene: PackedScene
@export var death_scene: PackedScene
@export var game_over_scene_path: String = "res://scenes/GameOver.tscn"
@export var game_over_delay: float = 1.8

@onready var entities: Node2D = $Entities
@onready var effects: Node2D = $Effects
@onready var tower: Node2D = $Entities/Tower
@onready var wizard: Wizard = $Entities/Tower/Wizard
@onready var range_circle: Node2D = $Entities/Tower/RangeCircle
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: CanvasLayer = $HUD
@onready var float_text: CanvasLayer = $FloatText


func _ready() -> void:
	effects.add_to_group("effects")
	GameState.new_run()
	range_circle.call("set_radius", wizard.attack_range)
	_spawn_trees()
	spawner.zombie_spawned.connect(_on_zombie_spawned)
	spawner.wave_incoming.connect(hud.show_wave_banner)
	GameState.tower_destroyed.connect(_on_tower_destroyed)
	AudioManager.play_music()
	spawner.start(tower)


func _spawn_trees() -> void:
	if tree_textures.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234  # same forest every run
	for i in tree_count:
		var a := TAU * float(i) / float(tree_count) + rng.randf_range(-0.07, 0.07)
		var r := 1.0 + rng.randf_range(-0.07, 0.07)
		var tex := tree_textures[rng.randi() % tree_textures.size()]
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(2, 2)
		s.offset = Vector2(0.0, -tex.get_height() * 0.5 + 2.0)
		s.position = tower.position + Vector2(cos(a) * tree_ring_radius.x * r, sin(a) * tree_ring_radius.y * r)
		s.flip_h = rng.randf() < 0.5
		entities.add_child(s)


func _on_zombie_spawned(z: Zombie) -> void:
	z.damaged.connect(_on_zombie_damaged)
	z.died.connect(_on_zombie_died)


func _on_zombie_damaged(amount: float, crit: bool, pos: Vector2) -> void:
	var n := damage_number_scene.instantiate() as Node2D
	float_text.add_child(n)  # screen-space layer so text stays crisp under the 2x camera
	n.position = get_viewport().get_canvas_transform() * pos
	n.call("show_value", amount, crit)


@warning_ignore("integer_division")
func _on_zombie_died(z: Zombie) -> void:
	GameState.add_kill()
	var p := death_scene.instantiate() as CPUParticles2D
	effects.add_child(p)
	p.global_position = z.hit_point()
	p.color = z.blood_color
	if z.kind == Zombie.Kind.BOSS:
		p.amount = 48
	elif z.kind == Zombie.Kind.TANK:
		p.amount = 26
	var n := mini(z.coin_value, 6)
	var each := z.coin_value / n
	var extra := z.coin_value - each * n
	for i in n:
		var c := coin_scene.instantiate() as Coin
		effects.add_child(c)
		c.global_position = z.global_position + Vector2(0.0, -10.0)
		c.setup(each + (1 if i < extra else 0), tower)


func _on_tower_destroyed() -> void:
	spawner.stop()
	AudioManager.stop_music()
	AudioManager.play("game_over")
	Engine.time_scale = 1.0
	await get_tree().create_timer(game_over_delay, true, false, true).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(game_over_scene_path)
