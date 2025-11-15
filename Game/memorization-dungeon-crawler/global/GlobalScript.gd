extends Node
#class_name GlobalScript

static var CARD_MISSING_IMAGE = "res://assets/icons/card_missing_image.png"
static var totalArenas = 0

signal fact_answering_mode
signal adventure_mode
signal signal_game_over
signal signal_victory

static var SAVE_FILE


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

func game_over_event():
	signal_game_over.emit()
	questions.clear()
	clear_flashcard()

func victory_event():
	signal_victory.emit()

func start_game(entry:SaveEntry, goToLevel:bool = true):
	SaveHandler.currentGame = entry
	CardsHandler.load_from_file(SaveHandler.currentGame.path+"/cards.json")
	LevelsHandler.load_from_file(SaveHandler.currentGame.path+"/level.json")
	print("Loaded %d levels" % LevelsHandler.levels.size())
	_load_level_current_game()
	if(goToLevel):
		go_to_level()

func redo_level(goToLevel:bool = true):
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	_load_level_current_game()
	if(goToLevel):
		go_to_level()

func next_level(goToLevel:bool = true):
	SaveHandler.currentGame.completed_level+=1
	
	if(SaveHandler.currentGame.completed_level > LevelsHandler.levels.size()):
		#Just replay the final level again
		SaveHandler.currentGame.completed_level = LevelsHandler.levels.size()
		
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	_load_level_current_game()
	if(goToLevel):
		go_to_level()

func go_home():
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	get_tree().change_scene_to_file("res://UI/mainMenu/main/main_menu.tscn")

func map(value, from_min, from_max, to_min, to_max):
	return to_min + (value - from_min) * (to_max - to_min) / (from_max - from_min)

func map_clamp(value, from_min, from_max, to_min, to_max):
	return clamp(to_min + (value - from_min) * (to_max - to_min) / (from_max - from_min),to_min,to_max)


#Spawn
const POTION = preload("uid://c4iomrx46ssjc")
func spawn_potion(pos:Vector3):
	var instance = POTION.instantiate()
	instance.global_position = Vector3(pos)
	add_child(instance)
	instance.linear_velocity = Vector3(0,10,0)
	return instance

const KEY = preload("uid://cima58l8yrht0")
func spawn_key(pos:Vector3, _is_boss_key:bool):
	var instance = KEY.instantiate()
	instance.global_position = Vector3(pos)
	add_child(instance)
	instance.is_boss_key = _is_boss_key
	return instance

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
static var deckSize:int = 0
static var succeeded:int = 0
static var questions:Array#[Question];
static var _flashcardNode:WorldFlashCard
static var failed_flashcards:Array[Question]
static var _allow_end_on_failure = false

func has_flashcard():
	return _current_flashcard_question!=null and _has_flashcard

func get_flashcard_question():
	return _current_flashcard_question

	

func clear_flashcard():
	if(has_flashcard()):
		_flashcardNode.visible = false
	_has_flashcard = false

func new_flashcard_question(current_flashcard_question2:Question):
	if(get_player().mode == Player.PlayerMode.GAME_OVER):
		return
	
	_current_flashcard_question = current_flashcard_question2
	current_flashcard_answer = ""
	_has_flashcard=true
	_flashcardNode.visible = true
	print("new_flashcard_question: ",current_flashcard_question2.toString())
	
	_flashcardNode.signal_new_flashcard.emit(_current_flashcard_question)
	signal_new_flashcard.emit(_flashcardNode, _current_flashcard_question)
	
	_flashcardNode.signal_flashcard_answer_changed.emit(current_flashcard_answer)
	signal_flashcard_answer_changed.emit(current_flashcard_answer)

signal signal_new_flashcard
signal signal_flashcard_single_drill
signal signal_flashcard_finished_drill
signal signal_flashcard_answer_changed
signal signal_boss_defeated

func boss_defeated_event(enemy:GoblinTrigger, accuracy_score:float):
	signal_boss_defeated.emit(enemy, accuracy_score)
	Globals.get_player().mode = Player.PlayerMode.STILL

func get_player() -> Player:
	var list = get_tree().get_nodes_in_group("player")
	if list.size() > 0:
		return list[0]
	return null

#Drill the player on flashcards
#Question2 = the questions
#flashcardElement the node to assign to the flashcards

func drill_flashcards(quantity:int, flashcardElement:WorldFlashCard, time_multiplier:float = 1):
	failed_flashcards.clear()
	var questions:Array[Question] = []
	for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, quantity):
		questions.append(card.toQuestion(time_multiplier, SaveHandler.currentLevel))
	drill_questions(questions, flashcardElement)

func drill_questions(questions2:Array[Question], flashcardElement:WorldFlashCard, begin_delay_sec:float = 0, _allow_end_on_failure2:bool = false):
	if(has_flashcard() and flashcardElement != _flashcardNode):
		print("There is already a set of flashcards being drilled!")
		return
	_flashcardNode = flashcardElement
	_allow_end_on_failure = _allow_end_on_failure2
	fact_answering_mode.emit(_flashcardNode)
	print("Drilling player on ",questions2.size()," cards.")
	deckSize = questions2.size()
	questions = questions2;
	succeeded = 0
	if begin_delay_sec > 0:
		await get_tree().create_timer(begin_delay_sec).timeout
	new_flashcard_question(questions[0])

func submit_flashcard(succeed:bool):
	var player =  get_player()
	var accuracy = 0
	var time_ms = _flashcardNode.get_time_elapsed_MS()
	var question = _current_flashcard_question
	if(succeed):
		accuracy = 100
		succeeded += 1

	for tag in _current_flashcard_question.card.tags:
		var existing_entry:SaveEntry.CardMastery = SaveHandler.currentGame.tag_mastery.get(tag, null)
		if existing_entry:
			existing_entry.update_accuracy(accuracy)
			existing_entry.update_speed(time_ms)
		else:
			SaveHandler.currentGame.tag_mastery[tag] = SaveEntry.CardMastery.new(time_ms, accuracy,1)
	
	_flashcardNode.signal_flashcard_single_drill.emit(succeed)
	signal_flashcard_single_drill.emit(_flashcardNode, succeed)
	questions.remove_at(0)
	
	if(!succeed):
		failed_flashcards.append(_current_flashcard_question)
		await get_tree().create_timer(1).timeout
	
	if(questions.size() > 0):
		new_flashcard_question(questions[0])
	else:
		#If we want the last one to be good, we will just keep reviewing missed cards until then
		if(!succeed and !_allow_end_on_failure):
			if failed_flashcards.size() > 0: #If we have a failed flashcard to review
				new_flashcard_question(failed_flashcards[0])
				failed_flashcards.pop_back()
				return
			else: #Otherwise pick a random card fron one of our tags (This should never happen)
				for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, 1):
					new_flashcard_question(card.toQuestion(1, SaveHandler.currentLevel))
					return

		_flashcardNode.signal_flashcard_finished_drill.emit(succeeded, deckSize)
		signal_flashcard_finished_drill.emit(_flashcardNode, succeeded, deckSize)
		failed_flashcards.clear()
		if(player !=null and player.health > 0):
			adventure_mode.emit()
		clear_flashcard()


func _input(event):
	if (get_player() == null or get_player().mode == Player.PlayerMode.FACTS) and has_flashcard():
		if event is InputEventKey:
			if event.pressed and not event.echo:
				if event.keycode == KEY_BACKSPACE:
					current_flashcard_answer = ""
					#if current_flashcard_answer.length() > 0:
						#current_flashcard_answer = current_flashcard_answer.substr(0, current_flashcard_answer.length() - 1)
				elif event.keycode == KEY_ENTER:
					submit_flashcard(get_flashcard_question().answerEquals(current_flashcard_answer))
				elif !(event.keycode in ignored_keys):
					var ch := char(event.unicode)
					if(event.as_text() != null and _current_flashcard_question.is_valid_key(event,current_flashcard_answer)):
						current_flashcard_answer += ch
					print("Answer: ",get_flashcard_question().answer_text)
					if(current_flashcard_answer.length() >= get_flashcard_question().max_answer_chars\
					or current_flashcard_answer.length() >= get_flashcard_question().get_answer_length()):
						submit_flashcard(get_flashcard_question().answerEquals(current_flashcard_answer))
				
				if(get_flashcard_question().answerEquals(current_flashcard_answer)):
					submit_flashcard(true)
				_flashcardNode.signal_flashcard_answer_changed.emit(current_flashcard_answer)
				signal_flashcard_answer_changed.emit(current_flashcard_answer)

static var rng = RandomNumberGenerator.new()

static func random_deterministic(seed: int, y: int) -> RandomNumberGenerator:
	rng.seed = int(hash(Vector2i(seed, y)))
	return rng
