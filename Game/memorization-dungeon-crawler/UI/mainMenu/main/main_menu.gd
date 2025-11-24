extends Control
class_name MainMenu

@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton
@onready var delete_confirm: Panel = %DeleteConfirm
@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var version: Label = $CanvasLayer/version
@onready var menu_message_box: MessageBox = $CanvasLayer/MessageBox
@onready var loading: Panel = %Loading

var delete_entry:SaveEntry

func confirm_deletion(_delete_entry:SaveEntry):
	menu_message_box.show_confirmation("Delete Game?","Are you sure you want to delete this game? There will be no going back!",\
										_on_delete_yes_pressed,_on_delete_no_pressed)
	delete_entry = _delete_entry

func _on_delete_no_pressed() -> void:
	delete_entry = null

func _is_inside(base_path: String, target_path: String) -> bool:
	base_path = base_path.simplify_path()
	target_path = target_path.simplify_path()
	return target_path.begins_with(base_path)

func _on_delete_yes_pressed() -> void:
	if(delete_entry!=null):
		if(_is_inside(Globals.CUSTOM_GAMES_DIR, delete_entry.path)):
			print("Deleting app-data dir: ",delete_entry.path)
			DirAccess.remove_absolute(delete_entry.path+"/cards.json")
			DirAccess.remove_absolute(delete_entry.path+"/level.json")
			DirAccess.remove_absolute(delete_entry.path)
		
		SaveHandler.saves.erase(delete_entry)
		SaveHandler.save_to_file(Globals.SAVE_FILE)
	reload()

#Load the game
func load_game(entry:SaveEntry):
	loading.visible = true #display a loading message
	do_later(0.1, func(): _begin_game(entry))
	
func _begin_game(entry:SaveEntry):
	var feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()
	if Globals.start_game(entry, true, feedback) == false:
		loading.visible = false
		menu_message_box.show_message("Error Loading Game", feedback.message)

func do_later(seconds: float, action: Callable):
	await get_tree().create_timer(seconds).timeout
	action.call()

const GAME_ENTRY = preload("uid://cw3i736uj4aib")

func reload():
	get_tree().reload_current_scene()

func _ready():
	loading.visible=false
	version.text = " v"+ProjectSettings.get_setting("application/config/version")
	SaveHandler.load_from_file(Globals.SAVE_FILE)
	for entry in SaveHandler.saves:
		var node = GAME_ENTRY.instantiate()
		v_box_container.add_child(node)
		node.setDetails(entry)
		print(entry)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_new_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/new game/newgame.tscn")
