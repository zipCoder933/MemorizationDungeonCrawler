extends RefCounted
class_name SaveEntry

var name: String
var path: String
var completed_level: int
var tag_mastery: Dictionary = {}  # tag (String) -> CardMastery
var seed:int

func _init(_name: String = "", _seed=0, _path: String = "", _completed_level: int = 0, _tag_mastery: Dictionary = {}):
	name = _name
	seed = _seed
	path = _path
	completed_level = _completed_level
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
		"completed_level": completed_level,
		"tag_mastery": mastery_data
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
		data.get("completed_level", 0),
		tag_mastery
	)

func toString() -> String:
	return "[SaveEntry: name='%s', path='%s', completed_level=%d, tag_mastery_count=%d]" % [name, path, completed_level, tag_mastery.size()]

# Simple CardMastery class
class CardMastery:
	var average_speed: float
	var average_accuracy: float
	var attempts: int

	func _init(_speed: float = 0.0, _accuracy: float = 0.0, _attempts: int = 0):
		average_speed = _speed
		average_accuracy = _accuracy
		attempts = _attempts


	func update_accuracy(new_accuracy: float):
		attempts += 1
		average_accuracy = ((average_accuracy * (attempts - 1)) + new_accuracy) / attempts


	func update_speed(new_speed: float):
		attempts += 1
		average_speed = ((average_speed * (attempts - 1)) + new_speed) / attempts

	const ATTEMPT_THRESHOLD := 5  # how many attempts needed for full confidence
	
	func get_mastery_level(slow_speed_ms:int, target_speed_ms:int) -> float:
		# Normalize accuracy (0–100) to 0–1
		var acc_factor = clamp(average_accuracy / 100.0, 0.0, 1.0)
		# Normalize speed (ms) to 0–1 (fast = 1, slow = 0)
		var speed_factor = clamp(Globals.map(average_speed, slow_speed_ms, target_speed_ms, 0, 1), 0,1)
		#Confidence
		#var confidence = clamp(Globals.map(average_speed, 0, 10, 0, 1), 0,1)
		
		var mastery = acc_factor * speed_factor

		# Combine everything
		#var adjusted_mastery = pow(mastery * confidence, 1.2)
		return mastery
		
	func to_dictionary() -> Dictionary:
		return {
			"average_speed": average_speed,
			"average_accuracy": average_accuracy,
			"attempts": attempts
		}
