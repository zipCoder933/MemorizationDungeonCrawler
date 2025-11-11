class_name Card

const Question = preload("uid://f2davn2or15j")
const Level = preload("uid://dbbavq1ux02yt")


var type: String
var question: String
var answer: String
var tags: Array
var is_image: bool
var directory: String #The directory of the cards.json file

func _init(_directory: String, _type: String, _question: String, _is_image:bool,  _answer: String, _tags: Array):
	type = _type.to_lower().strip_edges()
	question = _question
	directory = _directory
	answer = _answer
	is_image  = _is_image
	tags = _tags


func toQuestion(timeMultiplier:float, level:Level, fail_health_loss:float = 0.0):
	var isNumeric = false
	var allowNegative = true
	var allowDecimal = true
	var allowedKeys = ""
	var maxChars = 10

	if type == "number" or type == "numerical":
		isNumeric = true
	elif type == "integer":
		isNumeric = true
		allowNegative = true
		allowDecimal = false
	elif type == "natural" or type == "natural number" or type == "natural-number":
		isNumeric = true
		allowNegative = false
		allowDecimal = false
	elif type == "notes":
		allowedKeys = "abcdefg"
		maxChars = 1
	elif type == "text":
		maxChars = 50
	
	return Question.new(is_image, question, answer, level.time_to_answer_sec * timeMultiplier, fail_health_loss, \
		isNumeric, allowNegative, allowDecimal, allowedKeys,maxChars)

func toString() -> String:
	return "%s: %s = %s [%s]" % [type, question, answer, ", ".join(tags)]
