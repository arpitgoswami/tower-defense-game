extends Node
## Autoload "GameState": run state, upgrade formulas, costs, save/load.

signal coins_changed(coins: int)
signal hp_changed(hp: float, max_hp: float)
signal wave_changed(wave: int)
signal kills_changed(kills: int)
signal stats_changed
signal upgraded(stat: String)
signal tower_hit(amount: float)
signal tower_destroyed

const SAVE_PATH := "user://savegame.cfg"
const STATS: Array[String] = ["health", "damage", "strength", "durability"]

# ---------------------------------------------------------------- balance (tweak here)
@export_group("Health")
@export var base_max_hp: float = 100.0
@export var hp_per_level: float = 25.0
@export var base_regen: float = 0.5
@export var regen_per_level: float = 0.45
@export_group("Damage")
@export var base_damage: float = 12.0
@export var damage_per_level: float = 5.0
@export_group("Strength")
@export var base_knockback: float = 40.0
@export var knockback_per_level: float = 12.0
@export var base_crit_chance: float = 0.05
@export var crit_per_level: float = 0.03
@export var max_crit_chance: float = 0.70
@export var crit_multiplier: float = 2.0
@export var strength_damage_per_level: float = 0.06
@export_group("Durability")
@export var durability_factor: float = 0.93  ## damage taken is multiplied by this per level
@export var max_damage_reduction: float = 0.70
@export_group("Costs")
@export var cost_base: Dictionary = {"health": 18.0, "damage": 14.0, "strength": 22.0, "durability": 22.0}
@export var cost_growth: float = 1.27
@export_group("Economy")
@export var starting_coins: int = 0

# ---------------------------------------------------------------- run state
var levels: Dictionary = {}
var coins: int = 0
var hp: float = 100.0
var wave: int = 0
var kills: int = 0
var coins_earned: int = 0
var run_active: bool = false
var new_best: bool = false
var last_waves_survived: int = 0

# ---------------------------------------------------------------- saved data
var best_wave: int = 0
var best_kills: int = 0
var master_volume: float = 0.8
var muted: bool = false


func _ready() -> void:
	_reset_levels()
	load_data()
	apply_audio()


func _process(delta: float) -> void:
	if run_active and hp < max_hp():
		hp = minf(max_hp(), hp + regen() * delta)
		hp_changed.emit(hp, max_hp())


# ---------------------------------------------------------------- run control
func _reset_levels() -> void:
	for s in STATS:
		levels[s] = 0


func new_run() -> void:
	_reset_levels()
	coins = starting_coins
	coins_earned = 0
	kills = 0
	wave = 0
	hp = max_hp()
	run_active = true
	new_best = false
	coins_changed.emit(coins)
	kills_changed.emit(kills)
	wave_changed.emit(wave)
	hp_changed.emit(hp, max_hp())
	stats_changed.emit()


func set_wave(n: int) -> void:
	wave = n
	wave_changed.emit(wave)


func add_kill() -> void:
	kills += 1
	kills_changed.emit(kills)


func add_coins(amount: int) -> void:
	coins += amount
	coins_earned += amount
	coins_changed.emit(coins)


func damage_tower(amount: float) -> void:
	if not run_active:
		return
	var taken := amount * (1.0 - reduction())
	hp = maxf(0.0, hp - taken)
	tower_hit.emit(taken)
	hp_changed.emit(hp, max_hp())
	if hp <= 0.0:
		_end_run()


func _end_run() -> void:
	run_active = false
	last_waves_survived = maxi(wave - 1, 0)
	new_best = last_waves_survived > best_wave or (last_waves_survived == best_wave and kills > best_kills)
	if new_best:
		best_wave = last_waves_survived
		best_kills = kills
		save_data()
	tower_destroyed.emit()


# ---------------------------------------------------------------- stat formulas (level argument = preview support)
func level(stat: String) -> int:
	return int(levels.get(stat, 0))


func max_hp_at(l: int) -> float: return base_max_hp + hp_per_level * l
func regen_at(l: int) -> float: return base_regen + regen_per_level * l
func damage_at(l: int) -> float: return base_damage + damage_per_level * l
func knockback_at(l: int) -> float: return base_knockback + knockback_per_level * l
func crit_at(l: int) -> float: return minf(max_crit_chance, base_crit_chance + crit_per_level * l)
func dmg_mult_at(l: int) -> float: return 1.0 + strength_damage_per_level * l
func reduction_at(l: int) -> float: return minf(max_damage_reduction, 1.0 - pow(durability_factor, l))

func max_hp() -> float: return max_hp_at(level("health"))
func regen() -> float: return regen_at(level("health"))
func damage() -> float: return damage_at(level("damage"))
func knockback() -> float: return knockback_at(level("strength"))
func crit_chance() -> float: return crit_at(level("strength"))
func damage_multiplier() -> float: return dmg_mult_at(level("strength"))
func reduction() -> float: return reduction_at(level("durability"))


## Two lines "current -> next" for the upgrade buttons.
func preview_lines(stat: String) -> Array[String]:
	var l := level(stat)
	match stat:
		"health":
			return ["Max HP %d → %d" % [max_hp_at(l), max_hp_at(l + 1)],
					"Regen %.1f → %.1f/s" % [regen_at(l), regen_at(l + 1)]]
		"damage":
			return ["Damage %d → %d" % [damage_at(l), damage_at(l + 1)],
					"per spell"]
		"strength":
			return ["Knockback %d → %d" % [knockback_at(l), knockback_at(l + 1)],
					"Crit %d%% → %d%%  Dmg x%.2f → x%.2f" % [crit_at(l) * 100, crit_at(l + 1) * 100, dmg_mult_at(l), dmg_mult_at(l + 1)]]
		"durability":
			return ["Damage taken -%d%% → -%d%%" % [reduction_at(l) * 100, reduction_at(l + 1) * 100],
					"cap: -%d%%" % (max_damage_reduction * 100)]
	return ["", ""]


func is_maxed(stat: String) -> bool:
	return stat == "durability" and reduction_at(level(stat) + 1) <= reduction_at(level(stat)) + 0.0001


func cost(stat: String) -> int:
	return int(round(float(cost_base[stat]) * pow(cost_growth, level(stat))))


func can_afford(stat: String) -> bool:
	return coins >= cost(stat) and not is_maxed(stat)


func buy(stat: String) -> bool:
	if not run_active or not can_afford(stat):
		return false
	coins -= cost(stat)
	var old_max := max_hp()
	levels[stat] = level(stat) + 1
	if stat == "health":
		hp += max_hp() - old_max  # new max HP also heals by the difference
	coins_changed.emit(coins)
	hp_changed.emit(hp, max_hp())
	stats_changed.emit()
	upgraded.emit(stat)
	return true


# ---------------------------------------------------------------- save / settings
func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, muted)


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best_wave", best_wave)
	cfg.set_value("score", "best_kills", best_kills)
	cfg.set_value("settings", "master_volume", master_volume)
	cfg.set_value("settings", "muted", muted)
	cfg.save(SAVE_PATH)


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_wave = int(cfg.get_value("score", "best_wave", 0))
	best_kills = int(cfg.get_value("score", "best_kills", 0))
	master_volume = float(cfg.get_value("settings", "master_volume", 0.8))
	muted = bool(cfg.get_value("settings", "muted", false))
