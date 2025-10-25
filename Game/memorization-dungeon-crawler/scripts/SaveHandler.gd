extends Node
class_name SaveHandler

static var saves: Array[SaveEntry] = []

static func load_from_file(file_path: String) -> void:
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
