extends SceneTree
## Smoke test: menu -> settings -> play -> pause/speed/mute -> upgrades -> death -> game over -> retry/menu.
var step := 0
var frames := 0
var gs: Node

func _initialize() -> void:
	gs = root.get_node("GameState")
	change_scene_to_file("res://scenes/MainMenu.tscn")

func _process(_d: float) -> bool:
	frames += 1
	var cs := current_scene
	if cs == null or frames < 5: return false
	match step:
		0:
			cs.get_node("%SettingsButton").emit_signal("pressed")
			cs.get_node("%VolumeSlider").value = 0.5
			cs.get_node("%MuteCheck").button_pressed = true
			cs.get_node("%MuteCheck").button_pressed = false
			cs.get_node("%BackButton").emit_signal("pressed")
			print("menu ok: best label = ", cs.get_node("%HighScore").text, " vol=", gs.master_volume)
			cs.get_node("%PlayButton").emit_signal("pressed"); step = 1; frames = 0
		1:
			if cs.name != "Game": return false
			var hud := cs.get_node("HUD")
			hud.toggle_pause(); print("paused=", paused); hud.toggle_pause()
			hud.set_speed(3); print("scale=", Engine.time_scale); hud.set_speed(1)
			hud._toggle_mute(); hud._toggle_mute()
			gs.add_coins(500)
			for s in ["health","damage","strength","durability"]:
				cs.get_node("HUD/Root/Upgrades").get_children()[["health","damage","strength","durability"].find(s)].emit_signal("pressed")
			print("levels=", gs.levels, " coins=", gs.coins)
			for i in 40: gs.damage_tower(0.0)
			gs.damage_tower(99999.0); step = 2; frames = 0
		2:
			if frames > 900: print("ERROR: no gameover scene"); quit()
			if cs.name == "GameOver":
				print("gameover: ", cs.get_node("%Waves").text, "|", cs.get_node("%Kills").text, "|", cs.get_node("%Best").text, "| newbest visible=", cs.get_node("%NewBest").visible)
				cs.get_node("%RetryButton").emit_signal("pressed"); step = 3; frames = 0
		3:
			if cs.name == "Game" and frames > 10:
				print("retry ok, coins=", gs.coins, " hp=", gs.hp)
				change_scene_to_file("res://scenes/MainMenu.tscn"); step = 4; frames = 0
		4:
			if cs.name == "MainMenu" and frames > 10:
				print("back to menu ok. saved best_wave=", gs.best_wave); quit()
	return false
