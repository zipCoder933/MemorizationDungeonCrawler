extends Node
class_name FileUtils

static func _copy_file(src: String, dst: String) -> bool:
	# Read source
	var data = FileAccess.get_file_as_bytes(src)
	if data.is_empty():
		print("No data found in:", src)
		return false

	# Make sure the directory for `dst` exists
	var dir_path := dst.get_base_dir()  # peel off the filename like a banana
	var dir := DirAccess.open("user://")  # starting point for mkdirs

	if dir == null:
		print("Could not open user:// (that's… concerning)")
		return false

	# Recursively create all missing folders
	if DirAccess.make_dir_recursive_absolute(dir_path) != OK:
		print("Could not create directories for:", dir_path)
		return false

	# Now we can safely open the destination file
	var file := FileAccess.open(dst, FileAccess.WRITE)
	if file == null:
		print("Could not open the destination:", dst)
		return false

	file.store_buffer(data)
	return true

static func copy_game(origin:String, target:String):
	if _copy_file(origin+"/cards.json", target+"/cards.json"):
		if _copy_file(origin+"/level.json", target+"/level.json"):
			return true
		else:
			return false
	else:
		return false
	
