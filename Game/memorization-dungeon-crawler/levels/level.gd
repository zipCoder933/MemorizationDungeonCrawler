extends Node
class_name LevelData

@onready var ambient_sound: AudioStreamPlayer = %ambientSound
@onready var drill_submit: AudioStreamPlayer = $drill_submit

#We need a node in the level that holds the data for the entire level
#The global nodes are only _ready() when the game starts up
enum GameMode{
NORMAL, VICTORY, GAME_OVER	
}
var default_ambient_sound

var bossfight_ambient_sound = load("res://assets/sounds/gavin/music/bossfight.ogg")
var victory_ambient_sound = load("res://assets/sounds/pixabay/success-fanfare-trumpets-6185.mp3")

var game_mode:GameMode = GameMode.NORMAL
@export var auto_load_game = false

func _ready():
	if auto_load_game and Engine.is_editor_hint(): #For testing purposes
		print("Loaded save 0")
		SaveHandler.load_from_file(Globals.SAVE_FILE)
		Globals.start_game(SaveHandler.saves[0], false)

	game_mode = GameMode.NORMAL
	Globals._on_level_loaded()
	
	default_ambient_sound = LevelGenerator.getAmbientSound(SaveHandler.currentLevel)
	
	#Signals
	Globals.signal_flashcard_single_drill.connect(on_flashcard_single_drill)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.adventure_mode.connect(_global_adventure_mode)
	Globals.signal_victory.connect(_victory_event)
	
	#Start playing default sound
	_global_adventure_mode()

func _victory_event():
	ambient_sound.stream = victory_ambient_sound
	ambient_sound.stream.loop = false
	ambient_sound.play(0)
	
func _global_fact_answering_mode(_flashcardNode:WorldFlashCard):
	if _flashcardNode.parent !=null:
		if _flashcardNode.parent is GoblinTrigger:
			var trigger: GoblinTrigger = _flashcardNode.parent
			var isBoss = trigger.is_boss
			ambient_sound.stream = bossfight_ambient_sound
			ambient_sound.stream.loop = true
			ambient_sound.play(0)
	
func _global_adventure_mode():
	ambient_sound.stream = default_ambient_sound
	ambient_sound.stream.loop = true
	ambient_sound.play(0)
	
func on_flashcard_single_drill(_flashcardNode:WorldFlashCard, succeed:bool):
	if(succeed):
		drill_submit.play(0)
