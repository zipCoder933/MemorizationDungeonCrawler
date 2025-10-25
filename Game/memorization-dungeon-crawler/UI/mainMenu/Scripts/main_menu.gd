extends Control
@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton

const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")


const GAME_ENTRY = preload("uid://cw3i736uj4aib")
@onready var v_box_container: VBoxContainer = $CanvasLayer/ColorRect/LoadPanel/VBoxContainer/Panel/ScrollContainer/VBoxContainer


func _ready():
	SaveHandler.load_from_file(SaveHandler.SAVE_FILE)
	#start_game(SaveHandler.saves[0].path);
	for entry in SaveHandler.saves:
		var node = GAME_ENTRY.instantiate()
		v_box_container.add_child(node)
		node.setDetails(entry)
		print(entry)
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
	

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_new_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/newgame.tscn")
