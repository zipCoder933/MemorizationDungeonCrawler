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



var ignored_keys = [
	Key.KEY_SPACE,
	Key.KEY_ENTER,
	Key.KEY_UP, Key.KEY_DOWN, Key.KEY_LEFT, Key.KEY_RIGHT,
	Key.KEY_SHIFT, Key.KEY_CTRL, Key.KEY_ALT,
	Key.KEY_TAB, Key.KEY_ESCAPE, Key.KEY_BACKSPACE
]


static var _current_flashcard_question:Question
static var current_flashcard_answer:String
static var _has_flashcard:bool

func has_flashcard():
	return _current_flashcard_question!=null and _has_flashcard

func get_flashcard_question():
	return _current_flashcard_question

func clear_flashcard():
	_has_flashcard = false

func new_flashcard_question(current_flashcard_question2:Question):
	_current_flashcard_question = current_flashcard_question2
	current_flashcard_answer = ""
	_has_flashcard=true
	signal_new_flashcard.emit(_current_flashcard_question)
	signal_flashcard_answer_changed.emit(current_flashcard_answer)

signal signal_new_flashcard
signal signal_flashcard_submit_answer
signal signal_flashcard_answer_changed

func _input(event):
	if has_flashcard():
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.keycode == KEY_MINUS:
					current_flashcard_answer += "-"
				elif event.keycode == KEY_PLUS:
					current_flashcard_answer += "+"
				elif event.keycode == KEY_BACKSPACE:
					if current_flashcard_answer.length() > 0:
						current_flashcard_answer = current_flashcard_answer.substr(0, current_flashcard_answer.length() - 1)
				elif event.keycode == KEY_ENTER:
					signal_flashcard_submit_answer.emit(get_flashcard_question(), current_flashcard_answer)
					clear_flashcard()
				elif !(event.keycode in ignored_keys):
					if(event.as_text() != null):
						current_flashcard_answer += event.as_text()
				
				if(get_flashcard_question().answerEquals(current_flashcard_answer)):
					signal_flashcard_submit_answer.emit(get_flashcard_question(), current_flashcard_answer)
					clear_flashcard()
				signal_flashcard_answer_changed.emit(current_flashcard_answer)
					#print("ANSER: ",current_flashcard_answer)
			#else:#Any key released
				#anyKeyPressed = false
				#can_accept_input=true #If the player is on the button when we start the quiz, we cant answer until the player lifts the key off the button
