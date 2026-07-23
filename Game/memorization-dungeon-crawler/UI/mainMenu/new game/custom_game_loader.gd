extends Control
class_name CustomGameLoader

var newgame:NewGameUI

@onready var message_title: Label = %message_title
@onready var progress_bar: ProgressBar = $MessageBox/MarginContainer2/VBoxContainer/ProgressBar
@onready var progress_info: Label = %"progress info"
@onready var cancel_button: Button = %cancel_button
@onready var ok_button: Button = %ok_button

func _ready():
	self.hide()

func init(newgame: NewGameUI):
	self.newgame = newgame

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func progress(text:String, progress:float):
	progress_info.text = text;
	progress_bar.value = progress;
	print("CUSTOM GAME: ",text)
	
func load_custom_game(template_dir:String, dest_dir:String) -> bool:
	self.show()
	message_title.text = "Building custom game..."
	print("Making game in absolute directory: "+template_dir)
	progress_bar.value = 0
	
	#if(template_dir.ends_with(".zip")):
		#var zip := ZIPReader.new()
		#if zip.open(template_dir) == OK:
			#var files = zip.get_files()
			#for file_path in files:
				#var data = zip.read_file(file_path)
				## Create directories if needed
				#var dir_path = file_path.get_base_dir()
				#if dir_path != "":
					#DirAccess.make_dir_recursive_absolute("user://unzipped/" + dir_path)
				## Skip directories
				#if file_path.ends_with("/"):
					#continue
				#var file = FileAccess.open("user://unzipped/" + file_path, FileAccess.WRITE)
				#if file:
					#file.store_buffer(data)
					#file.close()
			#zip.close()
		#else:
			#print("Failed to open ZIP")
	
	#Load the game to ensure it works
	if newgame.load_game(template_dir):
		if(dest_dir != null):
			progress("Copying to Appdata dir", 0.5)
			var feedback = GameJsonLoadInfo.new()
			if FileUtils.copy_game(template_dir, dest_dir, feedback):
				template_dir = dest_dir
				print("Made game in directory: ",template_dir)
				if(newgame.load_game(dest_dir)):
					return true
			else:
				newgame.message_box.show_message("Unable to copy to AppData",feedback.message)
				return false
		else:
			progress("Building in directory", 0.5)
			return true
	return false


func _on_cancel_button_pressed() -> void:
	self.hide()


func _on_ok_button_pressed() -> void:
	self.hide()
