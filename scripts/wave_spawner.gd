class_name WaveSpawner
extends Node
## Builds waves, spawns zombies on an off-screen ring, tracks clears, emits banner signals.

signal wave_incoming(wave: int, is_boss: bool)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal zombie_spawned(zombie: Zombie)

enum State { IDLE, INTERMISSION, SPAWNING, FIGHTING }

@export var zombie_scene: PackedScene
@export var entities_path: NodePath
@export_group("Layout")
@export var spawn_radius: float = 620.0
@export_group("Wave size")
@export var base_count: int = 5
@export var count_per_wave: float = 1.3
@export var boss_every: int = 10
@export_group("Timing")
@export var first_wave_delay: float = 1.5
@export var intermission: float = 3.2
@export var spawn_interval_start: float = 1.5
@export var spawn_interval_min: float = 0.4
@export var spawn_interval_drop_per_wave: float = 0.04
@export_group("Difficulty growth (per wave, compounding for HP)")
@export var hp_growth: float = 0.095
@export var damage_growth: float = 0.05
@export var speed_growth: float = 0.012
@export var max_speed_mult: float = 1.45
@export var coin_growth: float = 0.10
@export var clear_bonus_base: int = 4
@export var clear_bonus_per_wave: int = 2

var wave: int = 0
var running: bool = false
var tower: Node2D

var _state: int = State.IDLE
var _timer: float = 0.0
var _queue: Array[int] = []
var _alive: int = 0
var _entities: Node


func _ready() -> void:
	_entities = get_node(entities_path)


func start(p_tower: Node2D) -> void:
	tower = p_tower
	running = true
	_prepare_next_wave(first_wave_delay)


func stop() -> void:
	running = false


func _prepare_next_wave(delay: float) -> void:
	wave += 1
	GameState.set_wave(wave)
	_state = State.INTERMISSION
	_timer = delay
	AudioManager.play("wave")
	wave_incoming.emit(wave, wave % boss_every == 0)


func _process(delta: float) -> void:
	if not running:
		return
	match _state:
		State.INTERMISSION:
			_timer -= delta
			if _timer <= 0.0:
				_queue = _build_queue(wave)
				_state = State.SPAWNING
				_timer = 0.0
				wave_started.emit(wave)
		State.SPAWNING:
			_timer -= delta
			if _timer <= 0.0 and not _queue.is_empty():
				_spawn(_queue.pop_front())
				_timer = maxf(spawn_interval_min, spawn_interval_start - spawn_interval_drop_per_wave * wave)
			if _queue.is_empty():
				_state = State.FIGHTING
		State.FIGHTING:
			if _alive <= 0:
				_on_cleared()


@warning_ignore("integer_division")
func _build_queue(w: int) -> Array[int]:
	var q: Array[int] = []
	var count := base_count + int(round(count_per_wave * (w - 1)))
	var fast_chance := 0.0
	if w >= 3:
		fast_chance = clampf((w - 2) * 0.05, 0.0, 0.35)
	var tank_chance := 0.0
	if w >= 5:
		tank_chance = clampf((w - 4) * 0.03, 0.0, 0.25)
	for i in count:
		var r := randf()
		if r < tank_chance:
			q.append(Zombie.Kind.TANK)
		elif r < tank_chance + fast_chance:
			q.append(Zombie.Kind.FAST)
		else:
			q.append(Zombie.Kind.NORMAL)
	if w % boss_every == 0:
		for i in w / boss_every:
			q.insert(q.size() / 2 + i, Zombie.Kind.BOSS)
	return q


func _spawn(kind: int) -> void:
	var z := zombie_scene.instantiate() as Zombie
	_entities.add_child(z)
	var angle := randf() * TAU
	z.global_position = tower.global_position + Vector2.from_angle(angle) * spawn_radius
	var hp_mult := pow(1.0 + hp_growth, wave - 1)
	var dmg_mult := 1.0 + damage_growth * (wave - 1)
	var speed_mult := minf(1.0 + speed_growth * (wave - 1), max_speed_mult)
	var coin_mult := 1.0 + coin_growth * (wave - 1)
	z.setup(kind, tower, hp_mult, dmg_mult, speed_mult, coin_mult)
	_alive += 1
	z.died.connect(_on_zombie_died)
	zombie_spawned.emit(z)


func _on_zombie_died(_z: Zombie) -> void:
	_alive = maxi(0, _alive - 1)


func _on_cleared() -> void:
	wave_cleared.emit(wave)
	GameState.add_coins(clear_bonus_base + clear_bonus_per_wave * wave)
	_prepare_next_wave(intermission)
