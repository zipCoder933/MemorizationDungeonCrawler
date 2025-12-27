extends Node
#class_name GlobalScript

#Signals
signal fact_answering_mode
signal adventure_mode
signal signal_game_over
signal signal_victory
signal signal_new_flashcard
signal signal_flashcard_single_drill
signal signal_flashcard_finished_drill
signal signal_flashcard_answer_changed
signal signal_show_bossfight_results
#signal signal_load_level

static var CARD_MISSING_IMAGE: Texture2D
static var SAVE_FILE
static var CUSTOM_GAMES_DIR
static var totalArenas = 0

##Flashcard stuff
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
static var themed_cards:int = 0
static var themed_succeeded:int= 0
static var succeeded:int = 0
static var questions:Array[Question];
static var _flashcardNode:WorldFlashCard
static var failed_flashcards:Array[Question]
static var _allow_end_on_failure = false

##If we are in the middle of a long bossfight, we may want to give our player a short break
static var FLASHCARD_BREAK_INTERVAL = 25
static var FLASHCARD_BREAK_TIME_MULTIPLIER = 1.6

static var _in_editor:bool

static func is_in_editor() -> bool:
	return _in_editor



func _ready():
	_in_editor = Engine.is_embedded_in_editor()
	print("Global loaded! In editor: ",is_in_editor())
	CARD_MISSING_IMAGE = load("res://assets/icons/card_missing_image.png")
	SAVE_FILE = ProjectSettings.globalize_path("user://save.json")
	CUSTOM_GAMES_DIR = ProjectSettings.globalize_path("user://data")
	var da := DirAccess.open("user://")
	da.make_dir_recursive(CUSTOM_GAMES_DIR)
	
	print("SAVE FILE: ", SAVE_FILE)
	#Write the new file if not exist
	if not FileAccess.file_exists(SAVE_FILE):
		print("Writing file...")
		var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
		file.store_string("{}")
		file.close()
		print("✨ Created empty JSON file at:", ProjectSettings.globalize_path(SAVE_FILE))

#Called by the level node
func _on_level_loaded():
	#print("Globals ready for new level!")
	clear_flashcard()

func game_over_event():
	if(get_level().game_mode != LevelData.GameMode.GAME_OVER):
		get_level().game_mode = LevelData.GameMode.GAME_OVER
		signal_game_over.emit()
		questions.clear()
		clear_flashcard()

func victory_event():
	if(get_level().game_mode != LevelData.GameMode.VICTORY):
		get_level().game_mode = LevelData.GameMode.VICTORY
		signal_victory.emit()
		SaveHandler.save_to_file(Globals.SAVE_FILE)

func get_base36_time() -> String:
	var ms: int = Time.get_ticks_msec()
	return String.num_int64(ms, 36)

#Loads the cards and levels before using the save entry
func load_cards_levels(dir_path:String, feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()) -> bool:
	if !DirAccess.dir_exists_absolute(dir_path):
		feedback.write("Directory \""+dir_path+"\" not found")
		return false
	
	#Load cards 
	var jsonFeedback = GameJsonLoadInfo.new()
	var out = CardsHandler.load_from_file(dir_path+"/cards.json",jsonFeedback,true)
	if(!out):
		feedback.write("Failed to load cards.json")
		feedback.write(jsonFeedback.message)
		return false
	
	#Load levels
	jsonFeedback = GameJsonLoadInfo.new()
	out = LevelsHandler.load_from_file(dir_path+"/level.json", jsonFeedback,true)
	if(!out):
		feedback.write("Failed to load level.json")
		feedback.write(jsonFeedback.message)
		return false

	return true



func load_game(entry:SaveEntry, successCall: Callable = Callable(), feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()):
	var loadingPanel:GameLoadingPanel = get_game_loading_panel()
	if(loadingPanel != null):
		loadingPanel.visible=true
		await get_tree().create_timer(0.01).timeout
	
	Callable(func():
		SaveHandler.currentGame = entry
		#load cards and levels
		if(load_cards_levels(SaveHandler.currentGame.path, feedback)):
			SaveHandler.currentGame.total_levels = LevelsHandler.levels.size()
			if successCall.is_valid():
				successCall.call()
		elif(get_message_box() != null):
			get_message_box().show_message("Error Loading Game", feedback.message)
		if(loadingPanel !=null):
			loadingPanel.visible = false
	).call()


func go_home():
	failed_flashcards = []
	clear_flashcard()
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

func has_flashcard():
	return _current_flashcard_question!=null and _has_flashcard

func get_flashcard_question():
	return _current_flashcard_question

func clear_flashcard():
	themed_succeeded = 0
	succeeded = 0
	themed_cards = 0
	if(_flashcardNode != null):
		_flashcardNode.visible = false
	_has_flashcard = false

func new_flashcard_question(current_flashcard_question2:Question):
	if(get_player() == null or get_player().mode != Player.PlayerMode.FACTS):
		#If the player says nope, forget about the new flashcard question
		return
	
	_current_flashcard_question = current_flashcard_question2
	current_flashcard_answer = ""
	_has_flashcard=true
	_flashcardNode.visible = true
	#print("new_flashcard_question: ",current_flashcard_question2.toString())
	
	_flashcardNode.signal_new_flashcard.emit(_current_flashcard_question)
	signal_new_flashcard.emit(_flashcardNode, _current_flashcard_question)
	
	_flashcardNode.signal_flashcard_answer_changed.emit(current_flashcard_answer)
	signal_flashcard_answer_changed.emit(current_flashcard_answer)


#Groups
func get_message_box() -> MessageBox:
	var list = get_tree().get_nodes_in_group("message_box")
	if list.size() > 0:
		return list[0]
	return null
	
func get_game_loading_panel() -> GameLoadingPanel:
	var list = get_tree().get_nodes_in_group("game_loading_panel")
	if list.size() > 0:
		return list[0]
	return null

func get_player() -> Player:
	var list = get_tree().get_nodes_in_group("player")
	if list.size() > 0:
		return list[0]
	return null

func get_level() -> LevelData:
	var list = get_tree().get_nodes_in_group("level")
	if list.size() > 0:
		return list[0]
	return null
	
func get_world_environment() -> WorldEnvironment:
	var list = get_tree().get_nodes_in_group("world_environment")
	if list.size() > 0:
		return list[0]
	return null

#Drill the player on flashcards
#Question2 = the questions
#flashcardElement the node to assign to the flashcards

func drill_flashcards(quantity:int, flashcardElement:WorldFlashCard, time_multiplier:float = 1):
	failed_flashcards.clear()
	var questions:Array[Question] = []
	for card in CardsHandler.get_random_cards(SaveHandler.get_current_level().card_tags, quantity):
		questions.append(card.toQuestion(time_multiplier, SaveHandler.get_current_level()))
	drill_questions(questions, flashcardElement)

func drill_questions(questions2:Array[Question], flashcardElement:WorldFlashCard, begin_delay_sec:float = 0, _allow_end_on_failure2:bool = false):
	if(has_flashcard() and flashcardElement != _flashcardNode):
		print("There is already a set of flashcards being drilled!")
		return
	if(questions2.size() == 0):
		print("Flashcard deck is empty!!!")
		return
	clear_flashcard()
	_flashcardNode = flashcardElement
	_allow_end_on_failure = _allow_end_on_failure2
	fact_answering_mode.emit(_flashcardNode)
	deckSize = questions2.size()
	questions = questions2;
	print("Drilling player on ",deckSize," cards.")
	if begin_delay_sec > 0:
		await get_tree().create_timer(begin_delay_sec).timeout
	new_flashcard_question(questions[0])

func _question_in_dungeon_themed_cards(question:Question) -> bool:
	for levelTag in SaveHandler.get_current_level().themed_card_tags:
		for tag in question.card.tags:
			if tag == levelTag:
				return true
	return false


	
func flashcard_remaining_count():
	return questions.size();
	
func flashcard_deck_size():
	return deckSize;

func submit_flashcard(succeed:bool):
	#If we dont have a flashcard anymore (We already submitted the last one)	
	if(!has_flashcard()):
		return
	var player =  get_player()
	player.play_submit_sound(succeed);
	var accuracy = 0
	var time_ms = _flashcardNode.get_time_elapsed_MS()
	var question = _current_flashcard_question

	if(succeed):
		accuracy = 100
		succeeded += 1
		
	if(_question_in_dungeon_themed_cards(question)):
		themed_cards +=1
		if(succeed):
			themed_succeeded += 1

	for tag in _current_flashcard_question.card.tags:
		var existing_entry:SaveEntry.CardMastery = SaveHandler.currentGame.tag_mastery.get(tag, null)
		if existing_entry:
			existing_entry.new_entry(accuracy,time_ms)
		else:
			SaveHandler.currentGame.tag_mastery[tag] = SaveEntry.CardMastery.new(time_ms, accuracy,1)
	
	_flashcardNode.drill_submit_time_ms = time_ms
	_flashcardNode.signal_flashcard_single_drill.emit(succeed)
	signal_flashcard_single_drill.emit(_flashcardNode, succeed)
	questions.remove_at(0)
	#Set current flashcard question to null to prevent from submitting twice
	_has_flashcard = false
	var totalCompletedCards = deckSize - questions.size()
	
	if(!succeed):
		failed_flashcards.append(_current_flashcard_question)
		await get_tree().create_timer(1).timeout
	
	if(questions.size() > 0):
		
		if(FLASHCARD_BREAK_INTERVAL > 0 and totalCompletedCards >= FLASHCARD_BREAK_INTERVAL and totalCompletedCards % FLASHCARD_BREAK_INTERVAL == 0):
			#If it has been more than 15 cards, give the user a short rest
			questions[0].time_limit *= FLASHCARD_BREAK_TIME_MULTIPLIER
		
		new_flashcard_question(questions[0])
	else:
		#If we want the last one to be good, we will just keep reviewing missed cards until then
		if(!succeed and !_allow_end_on_failure):
			if failed_flashcards.size() > 1: #If we have a failed flashcard to review
				new_flashcard_question(failed_flashcards[0])
				failed_flashcards.pop_back()
				return
			else: #Otherwise pick a random card fron one of our tags (This should never happen)
				for card in CardsHandler.get_random_cards(SaveHandler.get_current_level().card_tags, 1):
					new_flashcard_question(card.toQuestion(1, SaveHandler.get_current_level()))
					return

		var results:FlashcardDrillResults = FlashcardDrillResults.new(deckSize, themed_cards, succeeded, themed_succeeded, _flashcardNode)
		print("Drill finished. ",results.toString())
		_flashcardNode.signal_flashcard_finished_drill.emit(results)
		signal_flashcard_finished_drill.emit(results)
		failed_flashcards.clear()
		clear_flashcard()
		
		var isBossfight = false
		if(_flashcardNode.parent != null and _flashcardNode.parent is GoblinTrigger):
			var trigger:GoblinTrigger = _flashcardNode.parent
			isBossfight = trigger.is_boss
			if(isBossfight):
				print("waiting to show results...")
				Globals.get_player().mode = Player.PlayerMode.STILL
				await get_tree().create_timer(4).timeout
				signal_show_bossfight_results.emit(trigger, results)
				
		if(isBossfight==false and player !=null and player.health > 0):
			adventure_mode.emit()


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
