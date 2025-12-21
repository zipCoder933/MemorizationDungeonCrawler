extends Control
class_name MainMenu

@onready var v_box_container: VBoxContainer = %VBoxContainer

var delete_entry:SaveEntry

func confirm_deletion(_delete_entry:SaveEntry):
	Globals.get_message_box().show_confirmation("Delete Game?","Are you sure you want to delete this game? There will be no going back!",\
										_on_delete_yes_pressed,_on_delete_no_pressed)
	delete_entry = _delete_entry

func _on_delete_no_pressed() -> void:
	delete_entry = null



func _on_delete_yes_pressed() -> void:
	if(delete_entry!=null):
		FileUtils.delete_game(delete_entry)
		SaveHandler.saves.erase(delete_entry)
		SaveHandler.save_to_file(Globals.SAVE_FILE)
	reload()

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
