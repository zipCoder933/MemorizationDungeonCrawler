extends HBoxContainer
@onready var level: Label = %level
@onready var label: Label = %Label
var entry:SaveEntry
@onready var menu:MainMenu = get_tree().get_nodes_in_group("main menu")[0]


func setDetails(_entry:SaveEntry):
	entry = _entry
	label.text = entry.name
	if(entry.total_levels == 0):
		level.text = " (lvl "+ str(entry.completed_level+1)+" / -- )"
	else:
		level.text = " (lvl "+ str(entry.completed_level+1) +" / "+str(entry.total_levels)+")"
	
func _on_play_game_pressed() -> void:
	menu.load_game(entry)

func _on_delete_game_pressed() -> void:
	menu.confirm_deletion(entry)

func _on_view_mastery_pressed() -> void:
	MasteryPage.saveEntry = entry
	get_tree().change_scene_to_file("res://UI/mainMenu/gameInfo/gameInfo.tscn")
