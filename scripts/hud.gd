extends CanvasLayer
## HUD: HP, coins, wave, kills, pause / speed / mute, wave banner and the 4 upgrade buttons.

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var coins_label: Label = %CoinsLabel
@onready var wave_label: Label = %WaveLabel
@onready var kills_label: Label = %KillsLabel
@onready var pause_button: Button = %PauseButton
@onready var speed_buttons: Array[Button] = [%Speed1, %Speed2, %Speed3]
@onready var mute_button: Button = %MuteButton
@onready var banner: Label = %Banner
@onready var paused_label: Label = %PausedLabel

var _banner_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.coins_changed.connect(_on_coins)
	GameState.hp_changed.connect(_on_hp)
	GameState.wave_changed.connect(_on_wave)
	GameState.kills_changed.connect(_on_kills)
	pause_button.pressed.connect(toggle_pause)
	for i in speed_buttons.size():
		speed_buttons[i].pressed.connect(set_speed.bind(i + 1))
	mute_button.pressed.connect(_toggle_mute)
	banner.modulate.a = 0.0
	paused_label.visible = false
	_on_coins(GameState.coins)
	_on_hp(GameState.hp, GameState.max_hp())
	_on_wave(GameState.wave)
	_on_kills(GameState.kills)
	set_speed(1)
	_refresh_mute()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE, KEY_ESCAPE, KEY_P:
				toggle_pause()
			KEY_1:
				set_speed(1)
			KEY_2:
				set_speed(2)
			KEY_3:
				set_speed(3)
			KEY_M:
				_toggle_mute()


func toggle_pause() -> void:
	if not GameState.run_active:
		return
	var p := not get_tree().paused
	get_tree().paused = p
	paused_label.visible = p
	pause_button.text = "▶" if p else "II"


func set_speed(s: int) -> void:
	Engine.time_scale = float(s)
	for i in speed_buttons.size():
		speed_buttons[i].set_pressed_no_signal(i + 1 == s)


func _toggle_mute() -> void:
	GameState.muted = not GameState.muted
	GameState.apply_audio()
	GameState.save_data()
	_refresh_mute()


func _refresh_mute() -> void:
	mute_button.text = "MUTE" if not GameState.muted else "SOUND"


func show_wave_banner(wave: int, is_boss: bool) -> void:
	banner.text = "BOSS WAVE %d" % wave if is_boss else "WAVE %d" % wave
	banner.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if is_boss else Color(1, 0.95, 0.6))
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	banner.modulate.a = 0.0
	banner.scale = Vector2(1.6, 1.6)
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.4)
	_banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.5)


func _on_coins(c: int) -> void:
	coins_label.text = "Coins %d" % c


func _on_hp(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "HP %d / %d" % [ceili(hp), int(max_hp)]


func _on_wave(w: int) -> void:
	wave_label.text = "Wave %d" % w


func _on_kills(k: int) -> void:
	kills_label.text = "Kills %d" % k
