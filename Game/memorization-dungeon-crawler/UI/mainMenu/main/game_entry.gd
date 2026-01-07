extends HBoxContainer
@onready var level: Label = %level
@onready var label: Label = %Label
var entry:SaveEntry
@onready var menu:MainMenu = get_tree().get_nodes_in_group("main menu")[0]


func setDetails(_entry:SaveEntry):
	entry = _entry
	label.text = entry.name
	if(entry.total_levels == 0):
		level.text = " (lvl "+ str(entry.get_completed_level())+" / -- )"
	else:
		level.text = " (lvl "+ str(entry.get_completed_level()) +" / "+str(entry.total_levels)+")"
	
func _on_play_game_pressed() -> void:
	Globals.load_game(entry, func():
		SaveHandler.set_current_level(
			LevelsHandler.levels[SaveHandler.currentGame.get_completed_level()-1]
			)
		Globals.go_to_level()
	)


func _on_delete_game_pressed() -> void:
	menu.confirm_deletion(entry)

func _on_view_mastery_pressed() -> void:
	MasteryPage.saveEntry = entry
	get_tree().change_scene_to_file("res://UI/mainMenu/gameInfo/gameInfo.tscn")
