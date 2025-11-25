extends Panel
class_name FlashcardUI
@onready var time_left_bar: ProgressBar = %timeLeftBar
@onready var question_image: TextureRect = %questionImage
@onready var question_label: Label = %questionLabel
@onready var answer_label: Label = %answerLabel
@onready var background: ColorRect = %background
@export var worldFlashcardNode:WorldFlashCard;

const OPACITY = 0.9
const DEFAULT_COLOR = Color(0.194, 0.194, 0.194, OPACITY)
const FAILED_COLOR = Color(0.973, 0.0, 0.245, OPACITY)

var start_time:int
const DELAY_NEXT_CARD_MS = 500

var can_accept_input = false
var anyKeyPressed = false
var answer:String
var q:Question

func _drill_global(node:WorldFlashCard, q2:Question):
	_drill(q2)

#Put up a new flashcard
func _drill(q2: Question):
	time_left_bar.value = 1

	if q2.is_image:
		question_image.visible = true
		question_label.visible = false

		var tex: Texture2D = load(q2.question)
		if tex != null:
			question_image.texture = tex
		else:
			push_error("❌ Failed to load image at: " + q2.question)
			var tex2: Texture2D = load(Globals.CARD_MISSING_IMAGE)
			question_image.texture = tex2

	else:
		question_image.visible = false
		question_label.visible = true
		question_label.text = q2.question

	background.color = DEFAULT_COLOR
	answer_label.text = ""
	if anyKeyPressed:
		can_accept_input = false
	start_time = Time.get_ticks_msec()
	q = q2


func _submitted_global(node:WorldFlashCard, success:bool):
	_submitted(success)

func _submitted(success:bool):
	q = null
	start_time = Time.get_ticks_msec()
	if(!success):
		background.color = FAILED_COLOR

func _ready():
	Globals.signal_flashcard_answer_changed.connect(_flashcardAnswerChanged)
	
	if(worldFlashcardNode == null):
		Globals.signal_flashcard_single_drill.connect(_submitted_global)
		Globals.signal_new_flashcard.connect(_drill_global)
	else:
		worldFlashcardNode.signal_flashcard_single_drill.connect(_submitted)
		worldFlashcardNode.signal_new_flashcard.connect(_drill)

	
func get_time_elapsed_MS() -> int:
	return Time.get_ticks_msec() - start_time

func _process(delta:float):
	if(q != null && Globals.has_flashcard()):
		var timeElapsed = get_time_elapsed_MS()
		var timeLimitMS = q.time_limit * 1000
		time_left_bar.value = remap(timeElapsed, 0, timeLimitMS, 1, 0)
		#print("Time elapsed: ",timeElapsed," Time MS: ",timeLimitMS)
		
		if(timeElapsed > timeLimitMS + DELAY_NEXT_CARD_MS):
			Globals.submit_flashcard(false)
		elif(timeElapsed > timeLimitMS):
			background.color = FAILED_COLOR
		
		

func _flashcardAnswerChanged(answer:String):
	answer_label.text = answer
