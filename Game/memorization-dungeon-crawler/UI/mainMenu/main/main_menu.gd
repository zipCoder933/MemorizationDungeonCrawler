extends Control
class_name MainMenu

@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton
@onready var loading: Panel = %Loading
@onready var v_box_container: VBoxContainer = $CanvasLayer/ColorRect/LoadPanel/MarginContainer/Panel/ScrollContainer/VBoxContainer

#Load the game
func load_game(entry:SaveEntry):
	loading.visible = true #display a loading message
	#Start the game
	do_later(0.1, func(): Globals.start_game(entry))

func do_later(seconds: float, action: Callable):
	await get_tree().create_timer(seconds).timeout
	action.call()

const GAME_ENTRY = preload("uid://cw3i736uj4aib")

func reload():
	get_tree().reload_current_scene()

func _ready():
	SaveHandler.load_from_file(Globals.SAVE_FILE)
	for entry in SaveHandler.saves:
		var node = GAME_ENTRY.instantiate()
		v_box_container.add_child(node)
		node.setDetails(entry)
		print(entry)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_new_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/new game/newgame.tscn")
