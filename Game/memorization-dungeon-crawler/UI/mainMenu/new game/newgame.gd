extends Control
const SaveHandler = preload("uid://bgwdh30vglopu")

@onready var name_box: LineEdit = %nameBox
@onready var template_box: ItemList = %templateBox
@onready var message_box: MessageBox = %MessageBox
@onready var custom_template: LineEdit = %customTemplate
@onready var copy_game_to_appdata: CheckBox = %copyGameToAppdata
@onready var open_app_data: Button = %openAppData

func _on_files_dropped(files):
	print("Yummy files:", files)
	if(files.size()>0):
		custom_template.text = files[0]
		template_box.deselect_all()

func _ready():
	get_tree().get_root().connect("files_dropped", _on_files_dropped)
	if(Engine.is_embedded_in_editor()):
		template_box.add_item("Test")
	#var base_path = Globals.CUSTOM_GAMES_DIR
	#var da := DirAccess.open(Globals.CUSTOM_GAMES_DIR)
	#if da:
		#da.list_dir_begin()
		#var name := da.get_next()
		#while name != "":
			#if da.current_is_dir() and name != "." and name != "..":
				##var full_path = base_path.plus_file(name)
				##var card_status = LevelsHandler.load_from_file(full_path+"\\level.json")
				##var level_status = CardsHandler.load_from_file(full_path+"\\cards.json")
				#template_box.add_item(name)
			#name = da.get_next()
		#da.list_dir_end()


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
		
	if template_dir == null:
		message_box.show_message("No Template selected","You must either select a builtin template, or create one and enter the path in the text box")
		return
		
	if name_box.text.is_empty():
		message_box.show_message("Name is empty","You must enter a name for your game")
		return
	
	if load_game(template_dir):
		#Really stupid but we have to check if it starts with res to determine if its REALLY not absolute
		if DirAccess.dir_exists_absolute(template_dir) and !template_dir.strip_edges().begins_with("res://"):
			print("Making game in absolute directory: ",template_dir)
			#If this is a custom game, Copy the game into a new folder in our appData directory
			var dest_dir = Globals.CUSTOM_GAMES_DIR+"/"+name_box.text+" "+Globals.get_base36_time()
			if(copy_game_to_appdata.button_pressed):
				var feedback = GameJsonLoadInfo.new()
				if FileUtils.copy_game(template_dir, dest_dir, feedback):
					template_dir = dest_dir
					print("Made game in directory: ",template_dir)
					if(load_game(dest_dir)):
						_make_game(template_dir)
				else:
					message_box.show_message("Unable to copy to AppData",feedback.message)
					return
			else:
				_make_game(template_dir)
		else:
			print("Making game in resource directory: ",template_dir)
			#If this is not a custom game
			_make_game(template_dir)

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
	open_app_data.disabled = custom_template.text.is_empty()
	copy_game_to_appdata.disabled = new_text.is_empty()
	if new_text.is_empty() == false:
		template_box.deselect_all()

func _on_custom_template_focus_entered() -> void:
	open_app_data.disabled = custom_template.text.is_empty()
	copy_game_to_appdata.disabled = custom_template.text.is_empty()

func _on_copy_game_to_appdata_toggled(toggled_on: bool) -> void:
	if(!toggled_on):
		message_box.show_confirmation("Are you sure?",\
		"Setting this to unchecked means the game will be tied to the exact directory of the uploaded template. Moving or deleting this folder will cause the game to dissapear!",\
		Callable(), \
		func():copy_game_to_appdata.button_pressed = true )

func _on_open_app_data_pressed() -> void:
	OS.shell_open(Globals.CUSTOM_GAMES_DIR)
