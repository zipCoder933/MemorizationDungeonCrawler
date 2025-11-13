extends Control
class_name MasteryPage
@onready var v_box_container: VBoxContainer = $CanvasLayer/ColorRect/LoadPanel/MarginContainer/Panel/ScrollContainer/VBoxContainer
const MASTERY_ENTRY = preload("uid://ba4xtnhu7h7l5")
@onready var label: Label = $CanvasLayer/ColorRect/LoadPanel/Label

func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

static var saveEntry:SaveEntry

func _ready():
	if(saveEntry != null):
		#We want to load the game without entering the level
		Globals.start_game(saveEntry,false)
		
		label.text = "Mastery of \""+str(saveEntry.name)+"\"";
		print("Reading entries: ",saveEntry.tag_mastery.size())
		for tag in saveEntry.tag_mastery.keys():
			print("Reading ", tag," start ", LevelsHandler.start_speed," goal ", LevelsHandler.goal_speed)
			var entry:SaveEntry.CardMastery = saveEntry.tag_mastery[tag]
			var node = MASTERY_ENTRY.instantiate()
			v_box_container.add_child(node)
			node.set_details(tag, entry, LevelsHandler.start_speed, LevelsHandler.goal_speed)
