extends Panel
class_name FlashcardUI
@onready var time_left_bar: ProgressBar = %timeLeftBar
@onready var question_image: TextureRect = %questionImage
@onready var question_label: Label = %questionLabel
@onready var answer_label: Label = %answerLabel
@onready var background: ColorRect = %background
@export var worldFlashcardNode:WorldFlashCard;

const DEFAULT_COLOR = Color(0.617, 0.688, 0.694, 0.2)
const FAILED_COLOR = Color(0.973, 0.0, 0.245, 0.6)

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

		var img = Image.new()
		var path = (q2.question)  # ensure valid path
		var err = img.load(path)
		if err == OK:
			var tex = ImageTexture.create_from_image(img)
			question_image.texture = tex
		else:
			push_error("❌ Failed to load image at: " + path)
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

func _ready():
	Globals.signal_flashcard_answer_changed.connect(_flashcardAnswerChanged)
	
	if(worldFlashcardNode == null):
		Globals.signal_flashcard_single_drill.connect(_submitted_global)
		Globals.signal_new_flashcard.connect(_drill_global)
	else:
		worldFlashcardNode.signal_flashcard_single_drill.connect(_submitted)
		worldFlashcardNode.signal_new_flashcard.connect(_drill)

func _process(delta:float):
	if(q != null && Globals.has_flashcard()):
		var timeElapsed = Time.get_ticks_msec()-start_time
		var timeLimitMS = q.time_limit * 1000
		var timeLeft = remap(timeElapsed, 0, timeLimitMS, 1, 0)
		#print("Time elapsed: ",timeElapsed," Time MS: ",timeLimitMS)
		
		if(timeElapsed > timeLimitMS + DELAY_NEXT_CARD_MS):
			Globals.submit_flashcard(false)
		elif(timeElapsed > timeLimitMS):
			background.color = FAILED_COLOR
		
		time_left_bar.value = timeLeft

func _flashcardAnswerChanged(answer:String):
	answer_label.text = answer
