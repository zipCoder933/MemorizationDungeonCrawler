extends Node
#class_name GlobalScript

static var CARD_MISSING_IMAGE = "res://assets/icons/card_missing_image.png"
static var totalArenas = 0
static var completedArenas = 0

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
	await get_tree().create_timer(1).timeout
	signal_victory.emit()

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

func get_player() -> Player:
	var list = get_tree().get_nodes_in_group("player")
	if list.size() > 0:
		return list[0]
	return null

#Drill the player on flashcards
#Question2 = the questions
#flashcardElement the node to assign to the flashcards

func drill_flashcards(quantity:int, flashcardElement:WorldFlashCard):
	var questions:Array[Question] = []
	for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, quantity):
		questions.append(card.toQuestion(1, SaveHandler.currentLevel))
	drill_questions(questions, flashcardElement)

func drill_questions(questions2:Array[Question], flashcardElement:WorldFlashCard):
	_flashcardNode = flashcardElement
	_allow_end_on_failure = questions2.size() == 1
	fact_answering_mode.emit(_flashcardNode)
	print("Drilling player on ",questions2.size()," cards.")
	deckSize = questions2.size()
	questions = questions2;
	succeeded = 0
	new_flashcard_question(questions[0])

func submit_flashcard(succeed:bool):
	var player =  get_player()
	var accuracy = 0
	var time_ms = _flashcardNode.get_time_elapsed_MS()
	if(succeed):
		accuracy = 100
		succeeded += 1

	#Record speed and accuracy	
	print("time: ",time_ms," accuracy: ",accuracy)
	for tag in _current_flashcard_question.card.tags:
		var existing_entry:SaveEntry.CardMastery = SaveHandler.currentGame.tag_mastery.get(tag, null)
		if existing_entry:
			existing_entry.update_accuracy(accuracy)
			existing_entry.update_speed(time_ms)
			print("Entry size: ",SaveHandler.currentGame.tag_mastery.size())
			print("tag=",tag," accuracy=",existing_entry.average_accuracy," time ms=",existing_entry.average_speed)
		else:
			SaveHandler.currentGame.tag_mastery[tag] = SaveEntry.CardMastery.new(time_ms, accuracy,1)
	
	_flashcardNode.signal_flashcard_single_drill.emit(succeed)
	signal_flashcard_single_drill.emit(_flashcardNode, succeed)
	
	#If we did not succeed, lower the players health
	if(!succeed and player !=null):
		player.change_health( - get_flashcard_question().fail_health_loss)
	questions.remove_at(0)
	
	if(!succeed):
		failed_flashcards.append(_current_flashcard_question)
		await get_tree().create_timer(1).timeout
	
	if(questions.size() > 0):
		new_flashcard_question(questions[0])
	else:
		#If we want the last one to be good, we will just keep reviewing missed cards until then
		if(!succeed and !_allow_end_on_failure and failed_flashcards.size() > 0):
				new_flashcard_question(failed_flashcards[0])
				failed_flashcards.pop_back()
				return

		_flashcardNode.signal_flashcard_finished_drill.emit(succeeded, deckSize)
		signal_flashcard_finished_drill.emit(_flashcardNode, succeeded, deckSize)
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
					if(current_flashcard_answer.length() >= get_flashcard_question().max_answer_chars):
						submit_flashcard(get_flashcard_question().answerEquals(current_flashcard_answer))
				
				if(get_flashcard_question().answerEquals(current_flashcard_answer)):
					submit_flashcard(true)
				_flashcardNode.signal_flashcard_answer_changed.emit(current_flashcard_answer)
				signal_flashcard_answer_changed.emit(current_flashcard_answer)
