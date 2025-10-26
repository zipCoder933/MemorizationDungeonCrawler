extends Control
class_name HUD
@export var player:Player
@onready var damage_bar: ProgressBar = $CanvasLayer/DamageBar
@onready var label: Label = $CanvasLayer/Label

@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel
@onready var menu_panel: Panel = $MenuPanel
#@export var mouse_controller:MouseController
@onready var flashcard_panel: Panel = $flashcardPanel
@onready var flashcard_question: Label = %flashcardQuestion
@onready var flashcard_answer: Label = %flashcardAnswer
@onready var flashcard_time: ProgressBar = $flashcardPanel/VBoxContainer/flashcardTime

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")

func panelsVisible():
	return game_over_panel.visible or victory_panel.visible or menu_panel.visible

var current_question:Question

func hudQuestion(q:Question):
	current_question = q
	if(q == null):
		flashcard_panel.visible = false
	else:
		flashcard_time.value = 1
		flashcard_panel.visible = true
		flashcard_question.text = q.question
		flashcard_question.text = q.answer_text

func _ready():
	player.health_changed.connect(_player_health_changed)
	Globals.game_over.connect(_game_over)
	Globals.victory.connect(_victory)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			menu_panel.visible = !menu_panel.visible

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
	go_home()
func _on_back_pressed() -> void:
	go_home()
func _on_home_pressed() -> void:
	go_home()

func go_home():
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")

func _on_next_pressed() -> void:
	Globals.next_level()
