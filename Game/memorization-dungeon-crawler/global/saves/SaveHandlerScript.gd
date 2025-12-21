extends Node
class_name SaveHandler

static var saves:Array[SaveEntry] = []
static var currentGame:SaveEntry
static var _currentLevel:Level
static var muted:bool
static var graphics_render_scaling:float

static func get_current_level():
	return _currentLevel

static func set_current_level(level:int):
	if(level == -1):
		level = currentGame.get_completed_level()
	_currentLevel = LevelsHandler.get_level(level)

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
	graphics_render_scaling = parsed.get("graphics_render_scaling", 0.8)
	for entry_data in parsed.get("games", []):
		var save = SaveEntry.from_dictionary(entry_data)
		print(save.toString())
		saves.append(save)


static func save_to_file(file_path: String) -> void:
	var games_data: Array = []

	for save_entry in saves:
		if save_entry is SaveEntry:
			games_data.append(save_entry.to_dictionary())
		else:
			push_error("SaveHandler: Invalid object in saves array.")
			return

	var root_data: Dictionary = {
		"muted": muted,
		"graphics_render_scaling": graphics_render_scaling,
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
