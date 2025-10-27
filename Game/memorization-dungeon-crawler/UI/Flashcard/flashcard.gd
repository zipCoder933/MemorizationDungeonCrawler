extends Panel
class_name FlashcardUI
@onready var time_left_bar: ProgressBar = %timeLeftBar
@onready var question_image: TextureRect = %questionImage
@onready var question_label: Label = %questionLabel
@onready var answer_label: Label = %answerLabel
@onready var background: ColorRect = %background

const DEFAULT_COLOR = Color(0.617, 0.688, 0.694, 0.2)
const FAILED_COLOR = Color(0.973, 0.0, 0.245, 0.6)

var start_time:int
const DELAY_NEXT_CARD_MS = 500

var can_accept_input = false
var anyKeyPressed = false
var answer:String

signal signal_next_card

func _drill(q:Question):
	print("QUESITON: ",q.question)
	time_left_bar.value = 1
	start_time = Time.get_ticks_msec()
	if(q.is_image):
		question_image.visible = true
		question_label.visible = false
		#var img = Image.new()
		#var err = img.load(q.question)  # or an absolute path
		#if err == OK:
			#var tex = ImageTexture.create_from_image(img)
			#$Sprite3D.texture = tex
		#else:
			#push_error("Failed to load image!")
		#question_image.texture = Texture2D.new(q.question)
	else:
		question_image.visible = false
		question_label.visible = true
		question_label.text = q.question
	background.color = DEFAULT_COLOR
	answer_label.text = ""
	if(anyKeyPressed):
		can_accept_input = false

func _ready():
	Globals.signal_flashcard_answer_changed.connect(_flashcardAnswerChanged)
	Globals.signal_new_flashcard.connect(_drill)

func _process(delta:float):
	if(Globals.has_flashcard()):
		var q = Globals.get_flashcard_question()
		var ms = Time.get_ticks_msec()
		var timeLeft = remap(ms-start_time, 0,  q.time_limit * 1000, 1, 0)
		#print("T: ",ms-start_time," ",timeLeft)
		if(timeLeft < 0):
			background.color = FAILED_COLOR
		if(ms-start_time >  q.time_limit * 1000 + DELAY_NEXT_CARD_MS):
			signal_next_card.emit(q, false)
		time_left_bar.value = timeLeft

func _flashcardAnswerChanged(answer:String):
	answer_label.text = answer
