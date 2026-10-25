extends Control
## Main menu: animated clouds + fireflies, high score, settings panel.

@export var game_scene_path: String = "res://scenes/Game.tscn"
@export var cloud_speed: float = 28.0

@onready var clouds: Node2D = $Clouds
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var highscore_label: Label = %HighScore
@onready var settings_panel: Control = %SettingsPanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var mute_check: CheckBox = %MuteCheck
@onready var back_button: Button = %BackButton
@onready var menu_box: Control = %MenuBox
@onready var title: Label = %Title

var _t: float = 0.0


func _ready() -> void:
	AudioManager.play_music()
	play_button.pressed.connect(_on_play)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	back_button.pressed.connect(_on_back)
	volume_slider.value_changed.connect(_on_volume)
	mute_check.toggled.connect(_on_mute)
	volume_slider.set_value_no_signal(GameState.master_volume)
	mute_check.set_pressed_no_signal(GameState.muted)
	settings_panel.visible = false
	if GameState.best_wave > 0 or GameState.best_kills > 0:
		highscore_label.text = "Best run: %d waves survived, %d kills" % [GameState.best_wave, GameState.best_kills]
	else:
		highscore_label.text = "No runs yet. Defend the tower!"
	# stagger clouds
	var i := 0
	for c in clouds.get_children():
		(c as Sprite2D).position.x = 240.0 + i * 660.0
		i += 1
	play_button.grab_focus()


func _process(delta: float) -> void:
	_t += delta
	for c in clouds.get_children():
		var s := c as Sprite2D
		s.position.x += cloud_speed * (0.6 + 0.4 * float(s.get_index() % 3)) * delta
		if s.position.x > 2200.0:
			s.position.x = -280.0
	title.position.y = 80.0 + sin(_t * 1.6) * 10.0


func _on_play() -> void:
	AudioManager.play("upgrade")
	get_tree().change_scene_to_file(game_scene_path)


func _on_settings() -> void:
	menu_box.visible = false
	settings_panel.visible = true
	volume_slider.grab_focus()


func _on_back() -> void:
	GameState.save_data()
	settings_panel.visible = false
	menu_box.visible = true
	settings_button.grab_focus()


func _on_volume(v: float) -> void:
	GameState.master_volume = v
	GameState.apply_audio()
	AudioManager.play("coin")


func _on_mute(on: bool) -> void:
	GameState.muted = on
	GameState.apply_audio()
