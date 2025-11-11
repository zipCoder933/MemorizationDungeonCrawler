extends RefCounted
class_name SaveEntry

var name: String
var path: String
var completed_level: int

# This is the function the SaveHandler is looking for!
# It converts the object's essential data into a Dictionary, 
# which Godot can serialize into JSON.
func to_dictionary() -> Dictionary:
	return {
		"name": name,
		"path": path,
		"completed_level": completed_level
	}

func _init(_name: String = "", _path: String = "", _completed_level: int = 0):
	name = _name
	path = _path
	completed_level = _completed_level

func toString() -> String:
	return "[SaveEntry: name='%s', path='%s', completed_level=%d]" % [name, path, completed_level]
