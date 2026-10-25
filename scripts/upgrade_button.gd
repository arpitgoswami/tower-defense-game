extends Button
## One upgrade button: title, "current -> next" lines and an exponential cost (red when unaffordable).

@export var stat: String = "health"
@export var title: String = "HEALTH"
@export var affordable_color: Color = Color(1.0, 0.85, 0.3)
@export var unaffordable_color: Color = Color(1.0, 0.3, 0.3)

@onready var title_label: Label = %Title
@onready var line1: Label = %Line1
@onready var line2: Label = %Line2
@onready var cost_label: Label = %Cost


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	GameState.coins_changed.connect(func(_c: int) -> void: refresh())
	GameState.stats_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var lines := GameState.preview_lines(stat)
	title_label.text = "%s  Lv %d" % [title, GameState.level(stat)]
	line1.text = lines[0]
	line2.text = lines[1]
	if GameState.is_maxed(stat):
		cost_label.text = "MAXED"
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	else:
		cost_label.text = "Cost: %d" % GameState.cost(stat)
		cost_label.add_theme_color_override("font_color", affordable_color if GameState.can_afford(stat) else unaffordable_color)


func _on_pressed() -> void:
	if GameState.buy(stat):
		AudioManager.play("upgrade")
	else:
		AudioManager.play("deny")
