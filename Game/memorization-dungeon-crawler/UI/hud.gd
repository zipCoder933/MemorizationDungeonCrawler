extends Control

@export var player:Player
@onready var damage_bar: ProgressBar = $CanvasLayer/DamageBar
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel
@onready var label: Label = $CanvasLayer/Label

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")

func _ready():
	player.health_changed.connect(_player_health_changed)
	Globals.game_over.connect(_game_over)
	Globals.victory.connect(_victory)

func _process(delta):
	label.text = "COMPLETED ARENAS "+str(Globals.completedArenas)+" / "+str(Globals.totalArenas)
 
func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)

func _game_over():
	game_over_panel.visible = true

func _victory():
	victory_panel.visible = true

#back to home
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")

func _on_next_pressed() -> void:
	Globals.next_level()
