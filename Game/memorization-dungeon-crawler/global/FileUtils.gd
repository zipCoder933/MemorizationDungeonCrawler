extends Node
class_name FileUtils

static var valid_game_extensions:Array[String] = ["png","jpg","gif","json"]
static var GAME_MAX_SUBDIRS = 2

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

static func get_extensions_recursive(path: String, feedback:GameJsonLoadInfo, max_steps:int, steps:int = 1) -> Array:
	var exts := {}
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: %s" % path)
		return []
	
	dir.list_dir_begin()
	var fname := dir.get_next()
	
	while fname != "":
		if fname.begins_with("."):
			fname = dir.get_next()
			continue
		
		var full_path := path.path_join(fname)
		
		if dir.current_is_dir():
			if steps+1 > max_steps and max_steps > 0:
				feedback.write("Cannot copy folder with more than "+str(max_steps)+" directory levels.")
				return []
			else:
				var sub_exts = get_extensions_recursive(full_path, feedback, max_steps, steps+1)
				for e in sub_exts:
					exts[e] = true
		else:
			var ext := fname.get_extension()
			if ext != "":
				exts[ext] = true
		
		fname = dir.get_next()
	
	return exts.keys()

static func delete_recursive(path: String, max_steps:int, steps:int=1) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: %s" % path)
		return

	dir.list_dir_begin()
	var name := dir.get_next()

	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue

		var full := path.path_join(name)

		if dir.current_is_dir():
			if(max_steps == 0 or steps < max_steps):
				delete_recursive(full, max_steps, steps+1)
			DirAccess.remove_absolute(full)
		else:
			DirAccess.remove_absolute(full)

		name = dir.get_next()

	# Finally munch the directory itself
	DirAccess.remove_absolute(path)


static func copy_recursive(from_dir: String, to_dir: String) -> bool:
	var src := DirAccess.open(from_dir)
	if src == null:
		print("Can't open: %s" % from_dir)
		return false

	# Create target directory using a fresh DirAccess instance
	if DirAccess.make_dir_recursive_absolute(to_dir.get_base_dir()) != OK:
		print("Could not create directories for:" + to_dir.get_base_dir())
		return false
	
	src.list_dir_begin()
	var name := src.get_next()

	while name != "":
		if name.begins_with("."):
			name = src.get_next()
			continue

		var full_src := from_dir.path_join(name)
		var full_dst := to_dir.path_join(name)

		if src.current_is_dir():
			copy_recursive(full_src, full_dst)
		else:
			_copy_file(full_src, full_dst)

		name = src.get_next()
	return true

static func _is_inside(base_path: String, target_path: String) -> bool:
	base_path = base_path.simplify_path()
	target_path = target_path.simplify_path()
	return target_path.begins_with(base_path)

static func delete_game(delete_entry: SaveEntry) -> void:
	var canon_root   = ProjectSettings.globalize_path(Globals.CUSTOM_GAMES_DIR)
	var canon_target = ProjectSettings.globalize_path(delete_entry.path)

	# --- SAFETY CHECK 1: strict canonical containment ---
	if !canon_target.begins_with(canon_root + "/"):
		print("Path escapism detected, aborting delete.")
		return

	# --- SAFETY CHECK 2: never delete the root itself ---
	if canon_target == canon_root:
		print("Refusing to delete the ROOT custom games directory!")
		return

	# --- SAFETY CHECK 3: user-defined (redundant but safe) ---
	# This is now just an extra watchdog for peace of mind.
	if !_is_inside(canon_root, canon_target):
		print("is_inside() rejected the path — aborting delete.")
		return

	# --- PROCEED WITH DELETION ---
	print("\n\nDELETING app-data dir:", canon_target)

	var err := DirAccess.remove_absolute(canon_target)
	if err != OK:
		print("Directory wasn't empty, deleting all contents...")
		delete_recursive(canon_target, 0)



static func copy_game(origin:String, target:String, feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()):
	print("\n\nCOPYING game from  \"",origin,"\"  to  \"",target,"\"")
	#Check if the folder we are copying from is ok to begin with
	var has_valid_extensions = true
	
	var copy_feedback = GameJsonLoadInfo.new()
	var extensions = get_extensions_recursive(origin, copy_feedback, GAME_MAX_SUBDIRS)
	if !copy_feedback.message.is_empty():
		feedback.write(copy_feedback.message)
		return false
	
	for extension in extensions:
		if(!valid_game_extensions.has(extension)):
			has_valid_extensions = false

	if(has_valid_extensions):
		if FileAccess.file_exists(origin+"/cards.json") and FileAccess.file_exists(origin+"/level.json"):
			
			if copy_recursive(origin,target):
				return true
			else:
				feedback.write("Failed to copy directory")
				feedback.write(copy_feedback.message)
				return false
		else:
			feedback.write("Directory lacks essential files (cards.json and level.json)")
			return false
	else:
		feedback.write("Folder contains invalid files. Valid file types are " + str(valid_game_extensions))
		return false
	
static func load_texture_anywhere(path: String) -> Texture2D:
	# Normalize slashes
	path = path.replace("\\", "/")
	# ABSOLUTE PATH CASE 
	if path.is_absolute_path():
		var img := Image.new()
		var err := img.load(path)
		if err == OK:
			var tex := ImageTexture.create_from_image(img)
			return tex
		else:
			push_error("❌ Failed absolute load: " + path)
			return null
	# NON-ABSOLUTE (res:// or user:// or relative)
	var tex: Texture2D = load(path)
	if tex != null:
		return tex
	push_error("❌ Failed non-absolute load: " + path)
	return null


static func extract_archive(zip_path: String, destination_path: String) -> String:
	# Verify the ZIP exists.
	if not FileAccess.file_exists(zip_path):
		push_error("ZIP file does not exist: %s" % zip_path)
		return ""

	# Ensure the destination directory exists.
	var err := DirAccess.make_dir_recursive_absolute(destination_path)
	if err != OK:
		push_error("Failed to create destination directory: %s (Error %d)" % [destination_path, err])
		return ""

	var reader := ZIPReader.new()
	err = reader.open(zip_path)
	if err != OK:
		push_error("Failed to open ZIP file: %s (Error %d)" % [zip_path, err])
		return ""

	var entries := reader.get_files()
	#var root_folder := get_zip_root(entries)

	for zip_entry in entries:
		var target_path := destination_path.path_join(zip_entry)

		# Directory entry
		if zip_entry.ends_with("/"):
			err = DirAccess.make_dir_recursive_absolute(target_path)
			if err != OK:
				push_warning("Failed to create directory: %s" % target_path)
			continue

		# Make sure the parent directory exists.
		var parent_dir := target_path.get_base_dir()
		err = DirAccess.make_dir_recursive_absolute(parent_dir)
		if err != OK:
			push_error("Failed to create parent directory: %s" % parent_dir)
			reader.close()
			return ""

		# Read the file from the archive.
		var data := reader.read_file(zip_entry)

		# Write it to disk.
		var file := FileAccess.open(target_path, FileAccess.WRITE)
		if file == null:
			push_error("Failed to create file: %s" % target_path)
			reader.close()
			return ""

		file.store_buffer(data)
		file.close()

	reader.close()
	print("Successfully extracted '%s' to '%s'." % [zip_path, destination_path])
	#If the extracted path has a root folder, we need to append the root folder to get the full path to the archive's contents
	return destination_path

static func list_subpaths(path: String) -> Array[String]:
	var entries: Array[String] = []

	var dir := DirAccess.open(path)
	if dir == null:
		return entries

	for folder in DirAccess.get_directories_at(path):
		entries.append(path.path_join(folder))

	for file in DirAccess.get_files_at(path):
		entries.append(path.path_join(file))

	return entries

static func find_best_path(base_dir:String, base_path: String) -> String:
	base_dir = base_dir.replace("\\","/")
	base_path = base_path.replace("\\","/")
	
	# --- Clean the base dir ---
	if(base_dir.begins_with("res://")):
		base_dir = base_dir.lstrip("res://")
	if(base_path.begins_with("res://")):
		base_path = base_path.lstrip("res://")
	if(base_dir.begins_with("res:/")):
		base_dir = base_dir.lstrip("res:/")
	if(base_path.begins_with("res:/")):
		base_path = base_path.lstrip("res:/")
	
	# --- Clean the input path ---
	if(base_path.begins_with("../")):
		base_path = base_path.lstrip("../")
	if(base_path.begins_with("./")):
		base_path = base_path.lstrip("./")
	if(base_path.begins_with("/")):
		base_path = base_path.lstrip("/")
		
	# --- Build both possibilities ---
	var possible_paths := [
		"res://" + (base_dir + "/" +base_path).replace("//","/"),
		(base_dir + "/" +base_path).replace("//","/"),
		(base_dir.lstrip("/") + "/" +base_path).replace("//","/"),
		("/"+ base_dir + "/" +base_path).replace("//","/")
	]

	# --- Try both paths in order ---
	for path in possible_paths:
		#print("Testing ",path)
		if FileUtils.load_texture_anywhere(path) != null:
			#print("Found path: ",path)
			return path


	# --- If nothing worked ---
	push_error("❌ Could not find valid image path for: " + base_path)
	return ""  # indicate failure
