extends Control

@onready var progress_bar: ProgressBar = $ColorRect/VBoxContainer/ProgressBar
@onready var question_image: TextureRect = $ColorRect/VBoxContainer/question/questionImage
@onready var question_label: Label = $ColorRect/VBoxContainer/question/questionLabel
@onready var answer: Label = $ColorRect/VBoxContainer/answer

func _ready():
	progress_bar.min_value = 0
	progress_bar.max_value = 1
	progress_bar.value = 0.5
	question_image.visible = false
	question_label.text = "5+3"
	answer.text=""
