extends HBoxContainer
const SaveHandler = preload("uid://bgwdh30vglopu")
const LevelsHandler = preload("uid://bte11e0fapqes")

@onready var label: Label = %Label
var entry:SaveEntry

func start_game():
	CardsHandler.load_from_file(entry.path+"/cards.json")
	LevelsHandler.load_from_file(entry.path+"/level.json")
	print("Loaded %d levels" % LevelsHandler.levels.size())
	LevelsHandler.current_level = LevelsHandler.levels[0]
	get_tree().change_scene_to_file("res://levels/Level.tscn")

func setDetails(_entry:SaveEntry):
	entry = _entry
	print("ENTRY:",entry)
	label.text = entry.name
	
func _on_play_game_pressed() -> void:
	start_game()
	

func _on_delete_game_pressed() -> void:
	SaveHandler.saves.erase(entry)
	SaveHandler.save_to_file(SaveHandler.SAVE_FILE)
	get_tree().get_nodes_in_group("main menu")[0].reload()
