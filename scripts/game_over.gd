extends Control
## Game-over summary with Retry / Menu.

@export var game_scene_path: String = "res://scenes/Game.tscn"
@export var menu_scene_path: String = "res://scenes/MainMenu.tscn"

@onready var waves_label: Label = %Waves
@onready var kills_label: Label = %Kills
@onready var coins_label: Label = %Coins
@onready var best_label: Label = %Best
@onready var new_best_label: Label = %NewBest
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	waves_label.text = "Waves survived: %d" % GameState.last_waves_survived
	kills_label.text = "Zombies slain: %d" % GameState.kills
	coins_label.text = "Coins earned: %d" % GameState.coins_earned
	best_label.text = "Best: %d waves, %d kills" % [GameState.best_wave, GameState.best_kills]
	new_best_label.visible = GameState.new_best
	retry_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(game_scene_path))
	menu_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(menu_scene_path))
	retry_button.grab_focus()
