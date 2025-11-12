extends RefCounted
class_name SaveEntry

var name: String
var path: String
var completed_level: int
var card_mastery: Dictionary = {}  # Dictionary of Card -> CardMastery


func _init(_name: String = "", _path: String = "", _completed_level: int = 0, _card_mastery: Dictionary = {}):
	name = _name
	path = _path
	completed_level = _completed_level
	card_mastery = _card_mastery


# Converts this object to a Dictionary Godot can serialize
func to_dictionary() -> Dictionary:
	var mastery_data = {}
	for card in card_mastery.keys():
		var mastery: CardMastery = card_mastery[card]
		mastery_data[card] = mastery.to_dictionary()
	return {
		"name": name,
		"path": path,
		"completed_level": completed_level,
		"card_mastery": mastery_data
	}


func toString() -> String:
	return "[SaveEntry: name='%s', path='%s', completed_level=%d, card_mastery_count=%d]" % [name, path, completed_level, card_mastery.size()]


# Example CardMastery class for reference
class CardMastery:
	var average_speed: float
	var average_accuracy: float

	func _init(_speed: float = 0.0, _accuracy: float = 0.0):
		average_speed = _speed
		average_accuracy = _accuracy

	func get_mastery_level() -> int:
		# Example: simple calculation based on averages
		if average_accuracy > 0.9 and average_speed < 2.0:
			return 3  # Master
		elif average_accuracy > 0.75:
			return 2  # Intermediate
		else:
			return 1  # Beginner

	func to_dictionary() -> Dictionary:
		return {
			"average_speed": average_speed,
			"average_accuracy": average_accuracy,
			"mastery_level": get_mastery_level()
		}
