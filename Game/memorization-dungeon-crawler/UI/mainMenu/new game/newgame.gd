extends Control
class_name NewGameUI

const SaveHandler = preload("uid://bgwdh30vglopu")


@onready var name_box: LineEdit = %nameBox
@onready var template_box: ItemList = %templateBox
@onready var message_box: MessageBox = %MessageBox
@onready var custom_template: LineEdit = %customTemplate
@onready var copy_game_to_appdata: CheckBox = %copyGameToAppdata
@onready var open_app_data: Button = %openAppData
@onready var custom_game_loader: Control = $CanvasLayer/CustomGameLoader

func _on_files_dropped(files):
	if(files.size() > 0):
		custom_template.text = files[0]
		template_box.deselect_all()
	copy_game_to_appdata.disabled = custom_template.text.is_empty()

func _ready():
	get_tree().get_root().connect("files_dropped", _on_files_dropped)
	custom_game_loader.init(self)
	if(Engine.is_embedded_in_editor()):
		template_box.add_item("Test")

func _go_home():
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

func _on_cancel_button_pressed() -> void:
	_go_home();
	

func _on_start_button_pressed() -> void:
	var template_dir = null
	
	if template_box.is_anything_selected():
		var selected_indices: Array = template_box.get_selected_items()
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

	if(!custom_template.text.is_empty()):
		template_dir = custom_template.text

	if template_dir == null || template_dir.trim().is_empty():
		message_box.show_message("No Template selected","You must either select a builtin template, or create one and enter the path in the text box")
		return
		
	if name_box.text.is_empty():
		message_box.show_message("Name is empty","You must enter a name for your game")
		return
	
	if custom_template.text.is_empty(): #If this is not a custom game
		print("Making game in resource directory: ",template_dir)
		if(load_game(template_dir)):
			_make_game(template_dir)
	else: #If this IS a custom game
		if (DirAccess.dir_exists_absolute(template_dir) or FileAccess.file_exists(template_dir)) and !template_dir.strip_edges().begins_with("res://"):	
			var dest_dir = custom_game_loader.validate_and_build_custom_game(template_dir, name_box.text, copy_game_to_appdata.button_pressed)
			if(!dest_dir.is_empty()):
				_make_game(dest_dir)
		else:
			message_box.show_message("Invalid game path", "The path "+template_dir+" Does not exist or is invalid.")


func _make_game(template_dir:String):
	print("NAME: ",name_box.text," DIR: ",template_dir)
	var seed = randi_range(-12233720365808,12233720368807)
	var save1 = SaveEntry.new(name_box.text, seed, template_dir, 1)
	SaveHandler.saves.append(save1)
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	_go_home()

func load_game(template_dir:String):
	var feedback = GameJsonLoadInfo.new()
	if Globals.load_cards_levels(template_dir,feedback):
		return true
	else:
		message_box.show_message("Unable to load game",feedback.message)
		print(feedback.message)
		return false

func _on_custom_template_text_changed(new_text: String) -> void:
	#open_app_data.disabled = custom_template.text.is_empty()
	copy_game_to_appdata.disabled = new_text.is_empty()
	if new_text.is_empty() == false:
		template_box.deselect_all()

func _on_custom_template_focus_entered() -> void:
	#open_app_data.disabled = custom_template.text.is_empty()
	copy_game_to_appdata.disabled = custom_template.text.is_empty()

func _on_copy_game_to_appdata_toggled(toggled_on: bool) -> void:
	if(!toggled_on):
		message_box.show_confirmation("Are you sure?",\
		"Setting this to unchecked means the game will be tied to the exact directory of the uploaded template. Moving or deleting this folder will cause the game to dissapear!",\
		Callable(), \
		func():copy_game_to_appdata.button_pressed = true )

func _on_open_app_data_pressed() -> void:
	OS.shell_open(Globals.CUSTOM_GAMES_DIR)

func _on_open_wiki_pressed() -> void:
	OS.shell_open("https://github.com/Lightning323/Cogni-Crawl/wiki/Custom-Flashcard-Games-in-Cogni%E2%80%90Crawl")
