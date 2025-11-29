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

static func get_extensions_recursive(path: String) -> Array:
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
			# Dive into the folder like a caffeinated squirrel
			var sub_exts = get_extensions_recursive(full_path)
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
			# Dive downward like a ravenous void-otter
			if(max_steps == 0 or steps < max_steps):
				delete_recursive(full, max_steps, steps+1)
			DirAccess.remove_absolute(full)
		else:
			DirAccess.remove_absolute(full)

		name = dir.get_next()

	# Finally munch the directory itself
	DirAccess.remove_absolute(path)


static func copy_recursive(from_dir: String, to_dir: String,\
	 feedback:GameJsonLoadInfo,\
	 max_steps:int, steps:int = 1) -> bool:
	var src := DirAccess.open(from_dir)
	if src == null:
		feedback.write("Can't open: %s" % from_dir)
		return false

	# Create target directory using a fresh DirAccess instance
	if DirAccess.make_dir_recursive_absolute(to_dir.get_base_dir()) != OK:
		feedback.write("Could not create directories for:" + to_dir.get_base_dir())
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
			# Tunnel deeper like a hyperactive gopher
			if max_steps == 0 or steps < max_steps:
				copy_recursive(full_src, full_dst, feedback, max_steps,steps)
			elif steps >= max_steps:
				feedback.write("Cannot copy folder with more than "+str(max_steps)+" subdirectories!")
				return false
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
		push_error("Path escapism detected, aborting delete.")
		return

	# --- SAFETY CHECK 2: never delete the root itself ---
	if canon_target == canon_root:
		push_error("Refusing to delete the ROOT custom games directory!")
		return

	# --- SAFETY CHECK 3: user-defined (redundant but safe) ---
	# This is now just an extra watchdog for peace of mind.
	if !_is_inside(canon_root, canon_target):
		push_error("is_inside() rejected the path — aborting delete.")
		return

	# --- PROCEED WITH DELETION ---
	print("\n\nDELETING app-data dir:", canon_target)

	var err := DirAccess.remove_absolute(canon_target)
	if err != OK:
		print("Directory wasn’t empty… sending in cleanup squad.")
		delete_recursive(canon_target, GAME_MAX_SUBDIRS)



static func copy_game(origin:String, target:String, feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()):
	print("\n\nCOPYING game from ",origin," to ",target)
	#Check if the folder we are copying from is ok to begin with
	var has_valid_extensions = true
	for extension in get_extensions_recursive(origin):
		if(!valid_game_extensions.has(extension)):
			has_valid_extensions = false

	if(has_valid_extensions):
		if FileAccess.file_exists(origin+"/cards.json") and FileAccess.file_exists(origin+"/level.json"):
			var copy_feedback = GameJsonLoadInfo.new()
			if copy_recursive(origin,target,copy_feedback,GAME_MAX_SUBDIRS):
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
	
	
