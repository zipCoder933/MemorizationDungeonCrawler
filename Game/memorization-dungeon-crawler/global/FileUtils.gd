extends Node

class_name FileUtils

static func get_dir_size(path:String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		print("Can't open directory:", path)
		return -1
	var total := 0
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file in [".", ".."]:
			file = dir.get_next()
			continue
		var full := path + "/" + file
		if dir.current_is_dir():
			var sub := get_dir_size(full)
			if sub < 0:
				return -1
			total += sub
		else:
			var f := FileAccess.open(path, FileAccess.READ)
			var size := f.get_length()
			total += size
		file = dir.get_next()
	dir.list_dir_end()
	return total
