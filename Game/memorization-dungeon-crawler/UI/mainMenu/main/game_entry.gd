extends HBoxContainer
@onready var level: Label = %level
@onready var label: Label = %Label
var entry:SaveEntry
@onready var menu:MainMenu = get_tree().get_nodes_in_group("main menu")[0]


func setDetails(_entry:SaveEntry):
	entry = _entry
	label.text = entry.name
	level.text = " (lvl "+ str(entry.completed_level) +")"
	
func _on_play_game_pressed() -> void:
	menu.load_game(entry)

func _on_delete_game_pressed() -> void:
	SaveHandler.saves.erase(entry)
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	menu.reload()

func _on_view_mastery_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/mastery/mastery.tscn")
