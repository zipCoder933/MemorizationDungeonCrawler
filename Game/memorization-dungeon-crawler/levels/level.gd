extends Node
class_name LevelData

#We need a node in the level that holds the data for the entire level
#The global nodes are only _ready() when the game starts up
enum GameMode{
NORMAL, VICTORY, GAME_OVER	
}
var game_mode:GameMode = GameMode.NORMAL

func _ready():
	print("Level ready!")
	game_mode = GameMode.NORMAL
	Globals._on_level_loaded()
