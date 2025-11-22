extends Control
const SaveHandler = preload("uid://bgwdh30vglopu")

@onready var name_box: LineEdit = $CanvasLayer/ColorRect/nameBox
@onready var template_box: ItemList = $CanvasLayer/ColorRect/templateBox

func _ready():
	if(Engine.is_embedded_in_editor()):
		template_box.add_item("Test")

func _go_home():
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

func _on_cancel_button_pressed() -> void:
	_go_home();
	

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
	elif selected_index == 3:#music
		template_dir = "res://data/games/music/"
	else:#test
		template_dir = "res://data/games/test/"

	print("NAME: ",name_box.text," TEMPLATE: ",template_dir)
	
	var seed = randi_range(-12233720365808,12233720368807)
	print("seed: ",seed)
	var save1 = SaveEntry.new(name_box.text, seed, template_dir, 0)
	SaveHandler.saves.append(save1)
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	_go_home()
