extends Node
class_name LevelData

#We need a node in the level that holds the data for the entire level
#The global nodes are only _ready() when the game starts up
enum GameMode{
NORMAL, VICTORY, GAME_OVER	
}
var game_mode:GameMode = GameMode.NORMAL
@export var auto_load_game = false

func _ready():
	if auto_load_game and Engine.is_editor_hint(): #For testing purposes
		print("Loaded save 0")
		SaveHandler.load_from_file(Globals.SAVE_FILE)
		Globals.start_game(SaveHandler.saves[0], false)
	print("Level ready!")
	game_mode = GameMode.NORMAL
	Globals._on_level_loaded()
