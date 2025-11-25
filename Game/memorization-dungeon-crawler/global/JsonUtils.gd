extends Node
class_name JsonUtils


static func get_typed(dict: Dictionary, key: String, expected_types, default, ):
	if not dict.has(key):
		return default
	var value = dict[key]
	var t = typeof(value)
	if typeof(expected_types) != TYPE_ARRAY:
		expected_types = [expected_types]
	return value if  expected_types.has(t) else default

static func get_string(dict: Dictionary, key: String, default: String = "") -> String:
	if not dict.has(key):
		return default
	
	var v = dict[key]
	var t = typeof(v)

	# Already a string?
	if t == TYPE_STRING:
		return v

	# Convert numbers and bools to string
	if t in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
		return str(v)

	# Arrays or dictionaries serialize cleanly
	if t in [TYPE_ARRAY, TYPE_DICTIONARY]:
		return JSON.stringify(v)

	return default


static func get_int(dict: Dictionary, key: String, default: int = 0) -> int:
	if not dict.has(key):
		return default

	var v = dict[key]
	var t = typeof(v)

	# Already int?
	if t == TYPE_INT:
		return v

	# Float can become int safely
	if t == TYPE_FLOAT:
		return int(v)

	# Bool → 0 or 1
	if t == TYPE_BOOL:
		return 1 if v else 0

	# String conversion attempt
	if t == TYPE_STRING:
		if v.is_valid_int():
			return int(v)
		if v.is_valid_float():
			return int(float(v))

	return default


static func get_float(dict: Dictionary, key: String, default: float = 0.0) -> float:
	if not dict.has(key):
		return default

	var v = dict[key]
	var t = typeof(v)

	# Already float?
	if t == TYPE_FLOAT:
		return v

	# Int → float
	if t == TYPE_INT:
		return float(v)

	# Bool → float
	if t == TYPE_BOOL:
		return 1.0 if v else 0.0

	# String conversion attempt
	if t == TYPE_STRING:
		if v.is_valid_float():
			return float(v)
		if v.is_valid_int():
			return float(int(v))

	return default


static func get_bool(dict: Dictionary, key: String, default: bool = false) -> bool:
	if not dict.has(key):
		return default

	var v = dict[key]
	var t = typeof(v)

	# Already bool?
	if t == TYPE_BOOL:
		return v

	# Numeric truthiness
	if t in [TYPE_INT, TYPE_FLOAT]:
		return v != 0

	# Strings: accept common truthy/falsey
	if t == TYPE_STRING:
		var s = v.strip_edges().to_lower()
		if s in ["true", "t", "yes", "y", "1"]:
			return true
		if s in ["false", "f", "no", "n", "0"]:
			return false
		# Also: numeric strings
		if v.is_valid_int():
			return int(v) != 0
		if v.is_valid_float():
			return float(v) != 0.0

	return default
