class_name Card

var type: String
var question: String
var answer: String
var tags: Array

func _init(_type: String, _question: String, _answer: String, _tags: Array):
	type = _type
	question = _question
	answer = _answer
	tags = _tags

func toString() -> String:
	return "%s: %s = %s [%s]" % [type, question, answer, ", ".join(tags)]
