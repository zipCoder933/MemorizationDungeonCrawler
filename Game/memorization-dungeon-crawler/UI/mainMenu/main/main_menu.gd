extends Control
class_name MainMenu

@onready var start_button: Button = $CanvasLayer/ColorRect/Buttons/StartButton
@onready var loading: Panel = %Loading
@onready var delete_confirm: Panel = %DeleteConfirm
@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var version: Label = $CanvasLayer/version

var delete_entry:SaveEntry

func confirm_deletion(_delete_entry:SaveEntry):
	delete_confirm.visible = true
	delete_entry = _delete_entry

func _on_delete_no_pressed() -> void:
	delete_entry = null
	delete_confirm.visible=false
	
func _on_delete_yes_pressed() -> void:
	delete_confirm.visible=false
	if( delete_entry!=null):
		SaveHandler.saves.erase(delete_entry)
		SaveHandler.save_to_file(Globals.SAVE_FILE)
	reload()

#Load the game
func load_game(entry:SaveEntry):
	loading.visible = true #display a loading message
	#Start the game
	do_later(0.1, func(): Globals.start_game(entry))

func do_later(seconds: float, action: Callable):
	await get_tree().create_timer(seconds).timeout
	action.call()

const GAME_ENTRY = preload("uid://cw3i736uj4aib")

func reload():
	get_tree().reload_current_scene()

func _ready():
	delete_confirm.visible=false
	loading.visible=false
	version.text = ProjectSettings.get_setting("application/config/version")
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
