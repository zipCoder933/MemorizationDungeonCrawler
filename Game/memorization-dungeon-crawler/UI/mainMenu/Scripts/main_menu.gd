extends Control
@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton

const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")


func _ready():
	SaveHandler.load_from_file("res://data/saveData.json")
	start_game(SaveHandler.saves[0].path);
	#start_button.pressed.connect(_on_button_pressed, ["Button1"])

func _on_start_button_pressed() -> void:
	print("hi")

func start_game(dir:String):
	CardsHandler.load_from_file(dir+"/cards.json")
	LevelsHandler.load_from_file(dir+"/level.json")
	
	print("Loaded %d levels" % LevelsHandler.levels.size())
	
	#Load a level
	LevelsHandler.current_level = LevelsHandler.levels[0]
	#get_tree().change_scene_to_file("res://levels/Level.tscn")
	
