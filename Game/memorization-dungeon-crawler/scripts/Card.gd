class_name Card

const Question = preload("uid://f2davn2or15j")
const Level = preload("uid://dbbavq1ux02yt")


var type: String
var question: String
var answer: String
var tags: Array

func _init(_type: String, _question: String, _answer: String, _tags: Array):
	type = _type
	question = _question
	answer = _answer
	tags = _tags

func toQuestion(timeMultiplier:float, level:Level, fail_health_loss:float = 0.0):
	var isImage = type == "image";
	return Question.new(isImage, question, answer, level.time_to_answer_sec * timeMultiplier, fail_health_loss)

func toString() -> String:
	return "%s: %s = %s [%s]" % [type, question, answer, ", ".join(tags)]
