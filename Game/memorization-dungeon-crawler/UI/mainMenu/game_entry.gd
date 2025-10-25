extends HBoxContainer
const SaveHandler = preload("uid://bgwdh30vglopu")
@onready var label: Label = %Label

var entry:SaveEntry

func setDetails(_entry:SaveEntry):
	entry = _entry
	print("ENTRY:",entry)
	label.text = entry.name
	
func _on_play_game_pressed() -> void:
	print("Playing game")
	

func _on_delete_game_pressed() -> void:
	SaveHandler.saves.erase(entry)
	SaveHandler.save_to_file(SaveHandler.SAVE_FILE)
