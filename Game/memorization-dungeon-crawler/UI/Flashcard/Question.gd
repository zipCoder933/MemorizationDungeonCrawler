extends Node
class_name Question

var question: String
var is_image:bool
var answer_text: String
var time_limit: float

func _init(isImage:bool, q: String = "", ans: String = "", time: float = 0.0):
	is_image = isImage
	question = q
	answer_text = ans
	time_limit = time
