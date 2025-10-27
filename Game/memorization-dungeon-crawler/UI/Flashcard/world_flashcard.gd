extends Sprite3D
class_name WorldFlashCard

var player:Player
@onready var card_ui: FlashcardUI = %CardUI

signal finished_drill
signal single_drill

const GLOBAL_NODE = preload("uid://d364dmqkqu5a0")

var deckSize:int = 0
var succeeded:int = 0
var questions:Array#[Question];

func drill(questions2:Array):
	visible = true
	Globals.fact_answering_mode.emit(self)
	print("Drilling player on ",questions2.size()," cards.")
	deckSize = questions2.size()
	questions = questions2;
	succeeded = 0
	card_ui.signal_next_card.connect(_nextCard)
	#Globals.signal_flashcard_answer_changed.connect(_flashcardAnswerChanged)
	Globals.signal_flashcard_submit_answer.connect(_flashcardAnswerSubmitted)
	Globals.new_flashcard_question(questions[0])

func _flashcardAnswerSubmitted(question:Question, answer:String):
	var success = question.answerEquals(answer)
	_nextCard(question, success)

func _ready():
	var list = get_tree().get_nodes_in_group("player")
	if list.size() > 0:
		player = list[0]
	visible = false

func _nextCard(question:Question, succeed:bool):
	print("Succeeded: ",succeed)
	if(succeed):
		succeeded += 1
	single_drill.emit(succeed)
	#If we did not succeed, lower the players health
	if(!succeed and player !=null):
		player.change_health( - question.fail_health_loss)
	questions.remove_at(0)
	if(questions.size() > 0):
		Globals.new_flashcard_question(questions[0])
	else:
		finished_drill.emit(succeeded, deckSize)
		if(player !=null and player.health > 0):
			Globals.adventure_mode.emit()
		visible = false
		Globals.clear_flashcard()
