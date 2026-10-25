extends SceneTree
## Headless balance/regression bot (not needed to play). Usage:
## godot --headless --fixed-fps 60 --path . -s tests/bot.gd -- <strategy> <max_sim_seconds>
var game: Node
var gs: Node
var t := 0.0
var max_t := 1800.0
var strat := "balanced"
var last_wave := 0
var done := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: strat = args[0]
	if args.size() > 1: max_t = float(args[1])
	gs = root.get_node("GameState")
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	Engine.time_scale = 2.0
	gs.tower_destroyed.connect(func() -> void: done = true)

func _process(delta: float) -> bool:
	t += delta
	if strat != "none":
		var order: Array[String] = ["damage", "health", "strength", "durability"]
		if strat == "dmg": order = ["damage"]
		var best: String = ""
		var best_cost: int = 1 << 30
		for s in order:
			if gs.can_afford(s) and gs.level(s) <= gs.level(order[0]) + 2 and gs.cost(s) < best_cost:
				best = s; best_cost = gs.cost(s)
		if best != "": gs.buy(best)
	if gs.wave != last_wave:
		last_wave = gs.wave
		print("t=%4ds wave=%d hp=%d/%d coins=%d kills=%d lv=%s" % [t, last_wave, gs.hp, gs.max_hp(), gs.coins, gs.kills, gs.levels])
	if done or t > max_t:
		print("END strat=%s wave=%d survived=%d kills=%d earned=%d t=%d" % [strat, gs.wave, gs.last_waves_survived, gs.kills, gs.coins_earned, t])
		quit()
	return false
