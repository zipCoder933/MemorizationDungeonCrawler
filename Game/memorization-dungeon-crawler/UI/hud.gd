extends Control
class_name HUD
@export var player:Player
@onready var damage_bar: ProgressBar = %DamageBar
@onready var label: Label = $CanvasLayer/Label
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel
@onready var card_ui: FlashcardUI = %CardUI
@onready var menu_panel: Panel = %MenuPanel
@onready var level_indicator: Label = %"level indicator"
@onready var loading_panel: Panel = $CanvasLayer/LoadingPanel
@onready var fps: Label = $fps

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")
var fade_speed = 0.8

func panelsVisible():
	return game_over_panel.visible or victory_panel.visible or menu_panel.visible

var current_question:Question
@onready var boss_info: Label = %boss_info

func _ready():
	game_over_panel.visible=false
	loading_panel.modulate.a = 1
	victory_panel.modulate.a = 0
	victory_panel.visible = false
	loading_panel.visible = true
	player.health_changed.connect(_player_health_changed)
	Globals.signal_game_over.connect(_game_over)
	Globals.signal_victory.connect(_victory)
	if(SaveHandler.currentLevel != null and  SaveHandler.currentGame !=null):
		boss_info.visible = SaveHandler.currentLevel.levelType == Level.LevelType.BOSS
		if(SaveHandler.currentLevel.levelType == Level.LevelType.BOSS):
			level_indicator.text = "LEVEL " +\
			 str(SaveHandler.currentGame.completed_level+1)+": "+\
			SaveHandler.currentLevel.boss_name + " ("+SaveHandler.currentLevel.level_name+")"
		else:
			level_indicator.text = "LEVEL " +\
			 str(SaveHandler.currentGame.completed_level+1)+": "+SaveHandler.currentLevel.level_name

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			menu_panel.visible = !menu_panel.visible

func _process(delta):
	fps.text = str(Engine.get_frames_per_second())+" fps"

	label.text = "KEYS: "+str(player.keys)+" / "+str(Globals.totalArenas) 
	card_ui.visible = Globals.has_flashcard()
	
	if(victory_panel.visible):
		victory_panel.modulate.a = victory_panel.modulate.a + (fade_speed * delta)
	
	loading_panel.modulate.a = loading_panel.modulate.a - (fade_speed * delta)
	if(loading_panel.modulate.a <= 0):
		loading_panel.visible = false

func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)

func _game_over():
	game_over_panel.visible = true

@onready var victory_text: Label = %VictoryText
@onready var next: Button = $CanvasLayer/VictoryPanel/Next

func _victory():
	print("VICTORY EVENT CALLED")
	if(SaveHandler.currentGame.completed_level >= LevelsHandler.levels.size()):
		victory_text.text = "Game Complete!"
		next.text = "Replay Final Level"
	victory_panel.visible = true

func _on_button_pressed() -> void:
	Globals.go_home()
func _on_back_pressed() -> void:
	Globals.go_home()
func _on_home_pressed() -> void:
	Globals.go_home()
func _on_next_pressed() -> void:
	Globals.next_level()
func _on_try_again_pressed() -> void:
	Globals.redo_level()
