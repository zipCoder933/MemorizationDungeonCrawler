extends Control
class_name MasteryPage
const MASTERY_ENTRY = preload("uid://ba4xtnhu7h7l5")
const LEVEL_ENTRY = preload("uid://bg6dyxvcv8cuf")
@onready var title: Label = %title

@onready var level_entries: VBoxContainer = %levelEntries
@onready var mastery_entries: VBoxContainer = %masteryEntries

@onready var mastery_panel: Panel = $CanvasLayer/ColorRect/LoadPanel/MarginContainer/VBoxContainer/mastery_panel
@onready var levels_panel: Panel = $CanvasLayer/ColorRect/LoadPanel/MarginContainer/VBoxContainer/levels_panel
@onready var loading_panel: GameLoadingPanel = $CanvasLayer/LoadingPanel



func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

static var saveEntry:SaveEntry

func _ready():
	selectTab(0)
	if(saveEntry != null):
		#We want to load the game without entering the level
		Globals.load_game(saveEntry, func():
			title.text = "\""+str(saveEntry.name)+"\"";
			print("Reading entries: ",saveEntry.tag_mastery.size())
			for tag in saveEntry.tag_mastery.keys():
				print("Reading ", tag," start ", LevelsHandler.start_speed," goal ", LevelsHandler.goal_speed)
				var entry:SaveEntry.CardMastery = saveEntry.tag_mastery[tag]
				var node = MASTERY_ENTRY.instantiate()
				mastery_entries.add_child(node)
				node.set_details(tag, entry, LevelsHandler.start_speed, LevelsHandler.goal_speed)
			
			var completed = saveEntry.get_completed_level()
			print("Reading levels: ",LevelsHandler.levels.size()," level - ",completed)
			for level in LevelsHandler.levels:
				_add_level_entry(level,completed)
				if(level.levelType == Level.LevelType.BOSS):
					var practiceLevel = Level.makePracticeLevel(level)
					_add_level_entry(practiceLevel,completed)
		)

func _add_level_entry(level:Level, completed:int):
	var node = LEVEL_ENTRY.instantiate()
	level_entries.add_child(node)
	node.set_details(saveEntry, level, level.level_index <= completed)

func _on_tab_bar_tab_selected(tab: int) -> void:
	selectTab(tab)
	
func selectTab(tab:int):
	if(tab == 0):
		mastery_panel.visible=true;
		levels_panel.visible=false;
	else:
		mastery_panel.visible=false;
		levels_panel.visible=true;
