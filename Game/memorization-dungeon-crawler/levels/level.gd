extends Node
class_name LevelData

@onready var ambient_sound: AudioStreamPlayer = %ambientSound
@onready var short_whoosh_sound: AudioStreamPlayer = %shortWhooshSound
@onready var victory_sound: AudioStreamPlayer = %victorySound
@onready var victory_music: AudioStreamPlayer = %victoryMusic


#We need a node in the level that holds the data for the entire level
#The global nodes are only _ready() when the game starts up
enum GameMode{
NORMAL, VICTORY, GAME_OVER	
}
var default_ambient_sound

var bossfight_ambient_sound = load("res://assets/sounds/gavin/music/bossfight.ogg")

var game_mode:GameMode = GameMode.NORMAL
@export var auto_load_game = false

func _ready():
	Globals.stop_music()
	game_mode = GameMode.NORMAL
	Globals._on_level_loaded()
	
	default_ambient_sound = LevelGenerator.getAmbientSound(SaveHandler.get_current_level())
	
	#Signals
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.adventure_mode.connect(_global_adventure_mode)
	Globals.signal_victory.connect(_victory_event)
	Globals.signal_game_over.connect(_gameover_event)
	Globals.signal_show_bossfight_results.connect(_global_boss_defeated)
	
	#Start playing default sound
	_global_adventure_mode()


#func _process(delta:float):
	#if(Globals.get_player().mode == Player.PlayerMode.STILL):
		#ambient_sound.volume_db = -10

func _global_boss_defeated(_boss:GoblinTrigger, results:FlashcardDrillResults):
	#Turn the boss volume down a little
	var tween = create_tween()
	tween.tween_property(ambient_sound, "volume_db", -5, 1)

func _gameover_event():
	if(bossfight_mode):
		#Turn boss music back up
		var tween = create_tween()
		tween.tween_property(ambient_sound, "volume_db", 0, 1)

func _victory_event():
	if(bossfight_mode):
		#Turn boss music back up
		var tween = create_tween()
		tween.tween_property(ambient_sound, "volume_db", 0, 1)
	else:
		ambient_sound.stop()
		play_victory_sounds()

func play_victory_sounds() -> void:
	victory_sound.play(0)
	victory_music.volume_db = -20.0
	var tween = create_tween()
	var target_db: float = 0.0;
	var fade_duration: float = 10.0;
	tween.tween_interval(3)#delay seconds
	tween.tween_callback(victory_music.play)
	tween.tween_property(victory_music, "volume_db", target_db, fade_duration)

var bossfight_mode = false


func _global_fact_answering_mode(_flashcardNode:WorldFlashCard):
	if _flashcardNode.parent !=null and _flashcardNode.parent is GoblinTrigger:
		var trigger: GoblinTrigger = _flashcardNode.parent
		bossfight_mode = trigger.is_boss
	
	if( _flashcardNode.fightMusic != null):
			ambient_sound.stream = _flashcardNode.fightMusic
			ambient_sound.stream.loop = true
			print("Starting music; bossfight: ",bossfight_mode)
			if(bossfight_mode):
				ambient_sound.volume_db = -10
				ambient_sound.play()
				var tween = create_tween()
				tween.tween_property(ambient_sound, "volume_db", 0, 1.5)
			else:
				ambient_sound.volume_db = 0
				ambient_sound.play(0)
	else:
		short_whoosh_sound.play(0)

func _global_adventure_mode():
	if(bossfight_mode):
		return
	if(ambient_sound.playing and ambient_sound.stream != default_ambient_sound):
		#Fade the boss / enemy music out first
		var tween = create_tween()
		tween.tween_property(ambient_sound, "volume_db", -80, 5)
		tween.tween_callback(func():
			ambient_sound.stop()
			ambient_sound.volume_db = 0
			ambient_sound.stream = default_ambient_sound
			ambient_sound.stream.loop = true
			ambient_sound.play()
		)
	elif(ambient_sound.stream != default_ambient_sound or (not ambient_sound.playing)):
		ambient_sound.stream = default_ambient_sound
		ambient_sound.stream.loop = true
		ambient_sound.play()

func _input(event: InputEvent) -> void:
	if Globals.is_in_editor() and event is InputEventKey and event.pressed and not event.echo:
		if(event.keycode == KEY_V):
			Globals.victory_event()
