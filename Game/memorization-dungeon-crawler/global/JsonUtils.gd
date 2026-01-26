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


## Safely returns a PackedStringArray. Converts elements to strings if possible.
static func get_string_array(dict: Dictionary, key: String, default: PackedStringArray = []) -> PackedStringArray:
	if not dict.has(key) or typeof(dict[key]) != TYPE_ARRAY:
		return default
	
	var result = PackedStringArray()
	for item in dict[key]:
		# Reuse your existing get_string logic by passing a dummy dict
		# or just handle the basic conversion here:
		if typeof(item) == TYPE_STRING:
			result.append(item)
		elif typeof(item) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
			result.append(str(item))
	return result


## Safely returns a PackedInt32Array or PackedInt64Array.
static func get_int_array(dict: Dictionary, key: String, default: PackedInt32Array = []) -> PackedInt32Array:
	if not dict.has(key) or typeof(dict[key]) != TYPE_ARRAY:
		return default
	
	var result = PackedInt32Array()
	for item in dict[key]:
		var t = typeof(item)
		if t == TYPE_INT:
			result.append(item)
		elif t == TYPE_FLOAT:
			result.append(int(item))
		elif t == TYPE_STRING and item.is_valid_int():
			result.append(item.to_int())
	return result


## Safely returns a PackedFloat32Array.
static func get_float_array(dict: Dictionary, key: String, default: PackedFloat32Array = []) -> PackedFloat32Array:
	if not dict.has(key) or typeof(dict[key]) != TYPE_ARRAY:
		return default
	
	var result = PackedFloat32Array()
	for item in dict[key]:
		var t = typeof(item)
		if t == TYPE_FLOAT:
			result.append(item)
		elif t == TYPE_INT:
			result.append(float(item))
		elif t == TYPE_STRING and item.is_valid_float():
			result.append(item.to_float())
	return result


## Returns an array of Dictionaries (useful for nested JSON structures).
static func get_dict_array(dict: Dictionary, key: String, default: Array[Dictionary] = []) -> Array[Dictionary]:
	if not dict.has(key) or typeof(dict[key]) != TYPE_ARRAY:
		return default
	
	var result: Array[Dictionary] = []
	for item in dict[key]:
		if typeof(item) == TYPE_DICTIONARY:
			result.append(item)
	return result


## Returns a Dictionary at the specific key, or an empty one if missing/wrong type.
static func get_dict(dict: Dictionary, key: String, default: Dictionary = {}) -> Dictionary:
	var v = dict.get(key)
	if typeof(v) == TYPE_DICTIONARY:
		return v
	return default
