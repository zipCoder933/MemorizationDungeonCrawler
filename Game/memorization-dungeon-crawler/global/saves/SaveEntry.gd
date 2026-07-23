extends RefCounted
class_name SaveEntry

#Save Entry relies on CardsHandler and LevelsHandler

var name: String
var path: String
var _completed_level: int #The completed level (1 is the first element)
var total_levels: int #Used for information on the menu
var tag_mastery: Dictionary = {}  # tag (String) -> CardMastery
var seed:int

func is_template_game():
	return path.begins_with("res:/")

func get_completed_level():
	return _completed_level
	
func set_completed_level(level:int):
	_completed_level = clamp(level, 1, LevelsHandler.levels.size())

func _init(_name: String = "", _seed=0, _path: String = "", _completed_level: int = 1, \
			_tag_mastery: Dictionary = {}, _total_levels = 0):
	name = _name
	seed = _seed
	path = _path
	total_levels = _total_levels
	self._completed_level = _completed_level
	tag_mastery = _tag_mastery



func to_dictionary() -> Dictionary:
	var mastery_data = {}
	for tag in tag_mastery.keys():
		var mastery: CardMastery = tag_mastery[tag]
		mastery_data[tag] = mastery.to_dictionary()
	
	return {
		"name": name,
		"seed": seed,
		"path": path,
		"completed_level": _completed_level,
		"tag_mastery": mastery_data,
		"total_levels": total_levels
	}

static func from_dictionary(data: Dictionary) -> SaveEntry:
	var tag_mastery: Dictionary = {}
	var tag_mastery_data = data.get("tag_mastery", {})

	for tag in tag_mastery_data.keys():
		var mastery_info = tag_mastery_data[tag]
		var mastery = CardMastery.new(
			mastery_info.get("average_speed", 0.0),
			mastery_info.get("average_accuracy", 0.0),
			mastery_info.get("attempts", 0)
		)
		tag_mastery[tag] = mastery

	return SaveEntry.new(
		data.get("name", ""),
		data.get("seed", 0),
		data.get("path", ""),
		data.get("completed_level", 1),
		tag_mastery,
		data.get("total_levels", 0),
	)

func toString() -> String:
	return "[SaveEntry: name='%s', path='%s', completed_level=%d, tag_mastery_count=%d]" % [name, path, _completed_level, tag_mastery.size()]

# Simple CardMastery class
class CardMastery:
	const MAX_ATTEMPTS := 600

	var average_speed_ms: float
	var average_accuracy: float
	var attempts: int

	func _init(_speed: float = 0.0, _accuracy: float = 0.0, _attempts: int = 0):
		average_speed_ms = _speed
		average_accuracy = _accuracy
		attempts = _attempts

	func new_entry(new_accuracy: float, new_speed: float):
		attempts += 1
		average_speed_ms += (new_speed - average_speed_ms) /  min(attempts, MAX_ATTEMPTS)
		average_accuracy += (new_accuracy - average_accuracy) / min(attempts, MAX_ATTEMPTS)

	func get_mastery_level(slow_speed_ms: int, target_speed_ms: int) -> float:
		var acc_factor = clamp(average_accuracy / 100.0, 0.0, 1.0)
		var speed_factor = Globals.map(average_speed_ms, slow_speed_ms, target_speed_ms, 0, 1)
		var experience_factor = min(1, clamp(attempts / MAX_ATTEMPTS, 0, 1))
		return acc_factor * speed_factor * experience_factor

	func to_dictionary() -> Dictionary:
		return {
			"average_speed": average_speed_ms,
			"average_accuracy": average_accuracy,
			"attempts": attempts
		}
