extends Node
class_name GlobalEvents

static var totalArenas = 0
static var completedArenas = 0

signal fact_answering_mode
signal adventure_mode
signal game_over
signal victory

static var SAVE_FILE
const SaveHandler = preload("uid://bgwdh30vglopu")
const LevelsHandler = preload("uid://bte11e0fapqes")
const CardsHandler = preload("uid://cc0wwewiey4d7")


func _ready():
	print("Global loaded!")
	SAVE_FILE = ProjectSettings.globalize_path("user://save.json")
	print("SAVE FILE: ", SAVE_FILE)
	
	#Write the new file if not exist
	if not FileAccess.file_exists(SAVE_FILE):
		print("Writing file...")
		var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
		file.store_string("{}")
		file.close()
		print("✨ Created empty JSON file at:", ProjectSettings.globalize_path(SAVE_FILE))

	

func start_game(entry:SaveEntry, goToLevel:bool = true):
	SaveHandler.currentGame = entry
	CardsHandler.load_from_file(SaveHandler.currentGame.path+"/cards.json")
	LevelsHandler.load_from_file(SaveHandler.currentGame.path+"/level.json")
	print("Loaded %d levels" % LevelsHandler.levels.size())
	_load_level_current_game()
	if(goToLevel):
		go_to_level()
	
func next_level(goToLevel:bool = true):
	SaveHandler.currentGame.completed_level+=1
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	_load_level_current_game()
	if(goToLevel):
		go_to_level()

func go_to_level():
	get_tree().change_scene_to_file("res://levels/Level.tscn")

func _load_level_current_game():
	if(SaveHandler.currentGame.completed_level > LevelsHandler.levels.size()-1):
		print("Game is complete! No more levels")
		return
	print("Loading level ",SaveHandler.currentGame.completed_level)
	SaveHandler.currentLevel = LevelsHandler.levels[SaveHandler.currentGame.completed_level]
