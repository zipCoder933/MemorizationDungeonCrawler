extends Node
class_name SaveHandler

static var saves:Array[SaveEntry] = []
static var currentGame:SaveEntry
static var _currentLevel:Level
static var muted:bool
static var graphics_level:int
static var loaded: bool = false

static func get_current_level():
	return _currentLevel
	
static func set_current_level(level:Level):
	_currentLevel = level

static func load_from_file(file_path: String) -> void:
	saves.clear()
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + file_path)
		return
	
	var content := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed == null:
		push_error("Failed to parse JSON from file: " + file_path)
		return

	print("Loading saves: ")
	muted = parsed.get("muted", false)
	graphics_level = parsed.get("graphics_level", 3)
	for entry_data in parsed.get("games", []):
		var save = SaveEntry.from_dictionary(entry_data)
		print(save.toString())
		saves.append(save)
	#Ensure we know the file is loaded
	loaded = true


static func save_to_file(file_path: String) -> void:
	#If we havent loaded yet, Load the file!
	if(!loaded):
		print("Save File hasn't been loaded yet! Loading now...");
		load_from_file(file_path)
		
	var games_data: Array = []

	for save_entry in saves:
		if save_entry is SaveEntry:
			games_data.append(save_entry.to_dictionary())
		else:
			push_error("SaveHandler: Invalid object in saves array.")
			return

	var root_data: Dictionary = {
		"muted": muted,
		"graphics_level": graphics_level,
		"games": games_data
	}
	var json_string: String = JSON.stringify(root_data, "\t")

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return

	file.store_string(json_string)
	file.close()

	print("✅ Saved %d games to: %s" % [saves.size(), file_path])
