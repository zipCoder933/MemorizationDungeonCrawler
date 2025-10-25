extends Node
class_name SaveHandler

static var SAVE_FILE = "res://data/saveData.json"
static var saves: Array[SaveEntry] = []

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

	saves.clear()

	print("Loading saves: ")
	for entry in parsed.get("games", []):
		var save := SaveEntry.new(
			entry.get("name", ""),
			entry.get("path", ""),
			entry.get("completed_level", 0)
		)
		print(save.toString())
		saves.append(save)

static func save_to_file(file_path: String) -> void:
	# 1. Prepare data: Convert the array of SaveEntry objects into an array of dictionaries.
	var games_data: Array = []
	for save_entry in saves:
		# We rely on the SaveEntry.to_dictionary() method to get JSON-compatible data.
		if save_entry is SaveEntry:
			games_data.append(save_entry.to_dictionary())
		else:
			push_error("SaveHandler: Invalid object found in 'saves' array. Aborting save.")
			return

	# 2. Create the final root dictionary structure that includes the array under the "games" key
	var root_data: Dictionary = {
		"games": games_data
	}

	# 3. Serialize the dictionary into a formatted JSON string
	# The "\t" argument adds tab indentation, making the saved file easy for humans to read.
	var json_string: String = JSON.stringify(root_data, "\t", true)

	# 4. Write the JSON string to the file
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		# FileAccess.WRITE should create the file if it doesn't exist, so this error 
		# usually means a permission or path issue.
		push_error("Failed to open file for writing: " + file_path)
		return

	file.store_string(json_string)
	file.close()
	
	print("Successfully saved %d games to: %s" % [saves.size(), file_path])
