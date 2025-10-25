extends Node
class_name Question

var question: String
var is_image:bool
var answer_text: String
var time_limit: float

func answerEquals(ans: String) -> bool:
	print("User entered:", ans, " answer: ", answer_text)

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


func is_numeric(s: String) -> bool:
	# returns true if s can be converted to a number
	if s == "":
		return false
	return s.is_valid_float() or s.is_valid_int()


func _init(isImage:bool, q: String = "", ans: String = "", time: float = 0.0):
	is_image = isImage
	question = q
	answer_text = ans
	time_limit = time
