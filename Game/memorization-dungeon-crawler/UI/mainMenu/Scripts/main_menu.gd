extends Control
@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton
const LevelsHandler = preload("uid://bte11e0fapqes")

func _ready():
	start_game();
	#start_button.pressed.connect(_on_button_pressed, ["Button1"])

#func _on_button_pressed(button_name):
	#print(button_name, "was pressed")

func _on_start_button_pressed() -> void:
	print("hi")
	pass # Replace with function body.

func start_game():
	LevelsHandler.load_levels("res://data/games/multiplication/level.json")
	print("Loaded %d levels" % LevelsHandler.levels.size())
