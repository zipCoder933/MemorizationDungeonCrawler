extends RefCounted
class_name SaveEntry

var name: String
var path: String
var completed_level: int

func _init(_name: String = "", _path: String = "", _completed_level: int = 0):
	name = _name
	path = _path
	completed_level = _completed_level

func toString() -> String:
	return "[SaveEntry: name='%s', path='%s', completed_level=%d]" % [name, path, completed_level]
