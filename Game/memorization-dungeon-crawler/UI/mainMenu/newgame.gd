extends Control
const SaveHandler = preload("uid://bgwdh30vglopu")

@onready var name_box: LineEdit = $CanvasLayer/ColorRect/nameBox
@onready var template_box: ItemList = $CanvasLayer/ColorRect/templateBox

func _on_cancel_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")
	

func _on_start_button_pressed() -> void:
	var selected_indices: Array = template_box.get_selected_items()
	if selected_indices.is_empty() or name_box.text.is_empty():
		return
	
	var template_dir = null
	var selected_index: int = selected_indices[0]
	
	if selected_index == 0:#multiplication
		template_dir = "res://data/games/multiplication/"
	elif selected_index == 1:#addition
		template_dir = "res://data/games/addition/"
	elif selected_index == 2:#subtraction
		template_dir = "res://data/games/subtraction/"
	else: #division
		template_dir = "res://data/games/division/"

	print("NAME: ",name_box.text," TEMPLATE: ",template_dir)
	
	var save1 = SaveEntry.new(name_box.text, template_dir, 0)
	SaveHandler.saves.append(save1)
	SaveHandler.save_to_file(SaveHandler.SAVE_FILE)
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")
