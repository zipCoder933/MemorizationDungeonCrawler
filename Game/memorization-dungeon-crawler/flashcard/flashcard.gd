extends Panel
class_name FlashcardUI
@onready var time_left_bar: ProgressBar = %timeLeftBar
@onready var question_image: TextureRect = %questionImage
@onready var question_label: Label = %questionLabel
@onready var answer_label: Label = %answerLabel
@onready var background: ColorRect = %background
@export var worldFlashcardNode:WorldFlashCard;
@onready var drill_left_bar: ProgressBar = %drillLeftBar
@onready var drill_left_label: Label = %drillLeftLabel

const OPACITY = 0.9
const DEFAULT_COLOR = Color(0.18, 0.18, 0.18, OPACITY)
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

		var tex: Texture2D = FileUtils.load_texture_anywhere(q2.question)
		if tex != null:
			question_image.texture = tex
		else:
			push_error("❌ Failed to load image at: " + q2.question)
			question_image.texture = Globals.CARD_MISSING_IMAGE

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
	if(!success):
		background.color = FAILED_COLOR
	if(q != null):
		answer_label.text = q.formattedAnswer()
	start_time = Time.get_ticks_msec()
	q = null

func _ready():
	drill_left_bar.value = 1;
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
		var remainingDrill:float = float(Globals.flashcard_remaining_count()) /  float(Globals.flashcard_deck_size())
		drill_left_bar.value = remainingDrill;
		drill_left_label.text = str(Globals.flashcard_remaining_count())+" / "+ str(Globals.flashcard_deck_size())
		
		var timeElapsed = get_time_elapsed_MS()
		var timeLimitMS = q.time_limit * 1000
		time_left_bar.value = remap(timeElapsed, 0, timeLimitMS, 1, 0)
		#print("Time elapsed: ",timeElapsed," Time MS: ",timeLimitMS)
		
		if(timeElapsed > timeLimitMS):
			answer_label.text = q.formattedAnswer()
			Globals.submit_flashcard(false)
			background.color = FAILED_COLOR


func _flashcardAnswerChanged(answer:String):
	if(q != null  && Globals.has_flashcard()):
		answer_label.text = answer
