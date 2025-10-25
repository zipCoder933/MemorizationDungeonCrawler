extends Sprite3D

@onready var progress_bar: ProgressBar = $SubViewport/Control/ColorRect/VBoxContainer/ProgressBar
@onready var question_image: TextureRect = $SubViewport/Control/ColorRect/VBoxContainer/question/questionImage
@onready var question_label: Label = $SubViewport/Control/ColorRect/VBoxContainer/question/questionLabel
@onready var answer: Label = $SubViewport/Control/ColorRect/VBoxContainer/answer
@onready var color_rect: ColorRect = $SubViewport/Control/ColorRect


var time_left_ms:float
var start_time:int
const DELAY_NEXT_CARD_MS = 500
const DEFAULT_COLOR = Color(0.617, 0.688, 0.694, 0.5)

signal finished_drill
signal single_drill



var succeeded:int = 0
var questions:Array#[Question];

func drill(questions2:Array):
	print("Drilling player on ",questions2.size()," cards.")
	questions = questions2;
	succeeded = 0
	_drill(questions[0])

func _drill(q:Question):
	visible = true
	print("Visible,",visible)
	progress_bar.value = 1
	time_left_ms = q.time_limit * 1000
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
	currentQuestion = q
	color_rect.color = DEFAULT_COLOR
	answer.text=""

var currentQuestion:Question;

func _ready():
	progress_bar.min_value = 0
	progress_bar.max_value = 1
	progress_bar.value = 0.5
	question_image.visible = false
	question_label.text = ""
	answer.text=""
	color_rect.color = DEFAULT_COLOR
	visible = false
	drill([ 
	Question.new(false, "5+5", "10", 5),
	Question.new(false, "10+10", "20", 5),
	Question.new(false, "15+15", "30", 5),
	Question.new(false, "20+20", "40", 5)
	 ])

func _nextCard(succeed:bool):
	if(succeed):
		succeeded += 1
	single_drill.emit(succeed)
	questions.remove_at(0)
	if(questions.size() > 0):
		_drill(questions[0])
	else:
		finished_drill.emit(succeeded)
		visible = false
		
func _process(delta:float):
	if(questions.size() > 0 and currentQuestion != null and visible):
		var ms = Time.get_ticks_msec()
		var timeLeft = remap(ms-start_time, 0, time_left_ms, 1, 0)
		if(timeLeft < 0):
			color_rect.color = Color(0.973, 0.0, 0.245, 0.5)
		if(ms-start_time > time_left_ms + DELAY_NEXT_CARD_MS):
			_nextCard(false)
		progress_bar.value = timeLeft

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name = OS.get_keycode_string(event.keycode)
		if key_name == "Backspace":
			if answer.text.length() > 0:
				answer.text = answer.text.substr(0, answer.text.length() - 1)
		elif key_name == "Enter":
			print("Entered:", answer.text)
		else:
			var char = event.as_text()
			if( char != null):
				answer.text += char
			
	#print("Answer ", answer.text ," Real: ",currentQuestion.answer_text)
	if(currentQuestion != null and answer.text.strip_edges() == currentQuestion.answer_text.strip_edges()):
		_nextCard(true)
