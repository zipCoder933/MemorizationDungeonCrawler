extends Node
class_name Question

var question: String
var is_image:bool
var answer_text: String
var time_limit: float
var key_whitelist:String = ""
var card:Card
var key_requires_numeric = false
var allow_negative = false
var allow_decimal = false
var max_answer_chars = 50

func _init(_card:Card, isImage:bool, q: String = "", ans: String = "", time: float = 0.0,\
			 _key_requires_numeric = false, _allow_negative=false, _allow_decimal=false,\
			 _key_whitelist = "", _max_answer_chars = 50):
	card = _card
	is_image = isImage
	question = q
	answer_text = ans
	time_limit = time
	key_requires_numeric = _key_requires_numeric
	key_whitelist = _key_whitelist
	allow_negative = _allow_negative
	allow_decimal = _allow_decimal
	max_answer_chars = _max_answer_chars

func answerEquals(ans: String) -> bool:
	var user_val = ans.strip_edges()
	var real_val = answer_text.strip_edges()

	# Check if both are numeric (integer or float)
	var user_is_num = is_numeric(user_val)
	var real_is_num = is_numeric(real_val)

	if user_is_num and real_is_num:
		# Compare numerically
		return float(user_val) == float(real_val)
	else:
		# Fallback to string comparison
		return user_val == real_val

func is_valid_key(event: InputEventKey, currentAnswer:String):
	if(currentAnswer.length() >= max_answer_chars):
		return false
	var code := event.unicode
	var ch := char(code)
	if key_whitelist.length() > 0:
		return key_whitelist.contains(ch) 
	elif key_requires_numeric:
		if ch >= "0" and ch <= "9":
			return true
		if ch == "-" and allow_negative and currentAnswer.strip_edges() == "":
			return true
		if ch == "." and allow_decimal:
			if "." in currentAnswer:
				return false
			return true
		return false
	return true

func is_numeric(s: String) -> bool:
	# returns true if s can be converted to a number
	if s == "":
		return false
	return s.is_valid_float() or s.is_valid_int()

func toString() -> String:
	if(is_image):
		return "image: "+str(question)+", answer: "+str(answer_text)+", time: "+str(time_limit)+"s";
	else:
		return "question: "+str(question)+", answer: "+str(answer_text)+", time: "+str(time_limit)+"s";
