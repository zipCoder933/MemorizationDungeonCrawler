extends HBoxContainer
const SaveHandler = preload("uid://bgwdh30vglopu")
const LevelsHandler = preload("uid://bte11e0fapqes")

@onready var label: Label = %Label
var entry:SaveEntry
@onready var menu:MainMenu = get_tree().get_nodes_in_group("main menu")[0]


func setDetails(_entry:SaveEntry):
	entry = _entry
	print("ENTRY:",entry)
	label.text = entry.name
	
func _on_play_game_pressed() -> void:
	menu.load_game(entry)

func _on_delete_game_pressed() -> void:
	SaveHandler.saves.erase(entry)
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	menu.reload()
