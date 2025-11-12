extends Control
class_name HUD
@export var player:Player
@onready var damage_bar: ProgressBar = $CanvasLayer/DamageBar
@onready var label: Label = $CanvasLayer/Label
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel
@onready var card_ui: FlashcardUI = %CardUI
@onready var menu_panel: Panel = %MenuPanel
@onready var level_indicator: Label = %"level indicator"

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")

func panelsVisible():
	return game_over_panel.visible or victory_panel.visible or menu_panel.visible

var current_question:Question

func _ready():
	player.health_changed.connect(_player_health_changed)
	Globals.signal_game_over.connect(_game_over)
	Globals.signal_victory.connect(_victory)
	if( SaveHandler.currentGame !=null ):
		level_indicator.text = "LEVEL " + str(SaveHandler.currentGame.completed_level)+": "+SaveHandler.currentLevel.level_name

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			menu_panel.visible = !menu_panel.visible

func _process(delta):
	label.text = "COMPLETED ARENAS "+str(Globals.completedArenas)+" / "+str(Globals.totalArenas) 
	card_ui.visible = Globals.has_flashcard()

func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)

func _game_over():
	game_over_panel.visible = true

func _victory():
	print("VICTORY EVENT CALLED")
	victory_panel.visible = true

#back to home
func _on_button_pressed() -> void:
	go_home()
func _on_back_pressed() -> void:
	go_home()
func _on_home_pressed() -> void:
	go_home()

#Save and quit
func go_home():
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

func _on_next_pressed() -> void:
	Globals.next_level()
