extends Control
class_name CustomGameLoader

var newgame:NewGameUI

@onready var message_title: Label = %message_title
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
	
func info(title:String = "",text:String="", progress:float=0):
	if(!title.is_empty()):
		message_title.text = title
	progress_info.text = text;
	#progress_bar.value = progress;
	print("CUSTOM GAME: ",text)

func fail(title:String, message:String):
	message_title.text = "Unable to load copied game"
	progress_info.text = message
	print("CUSTOM GAME: ",message)
	
func validate_and_build_custom_game(input_dir:String, game_name:String, copy_to_appdata:bool) -> String:
	var isArchive = false #Is the input file a directory or a .zip?
	
	if !DirAccess.dir_exists_absolute(input_dir):
		if input_dir.ends_with(".zip"):
			isArchive = true
		else:
			fail("Invalid game file", "File must be a .zip archive or a folder")
			return ""
			
	var dest_dir = input_dir
	var unique_game_name = game_name+" "+Globals.get_base36_time()
	if(copy_to_appdata):
		dest_dir = Globals.CUSTOM_GAMES_DIR.path_join(unique_game_name)
	elif(isArchive):
		dest_dir = input_dir.get_base_dir()
	
	self.show()
	info("Validating game...", "\nInput dir="+input_dir+"\n Output dir="+dest_dir, 0)
	if(isArchive): #If this is an archive
		dest_dir = FileUtils.extract_archive(input_dir, dest_dir.path_join(unique_game_name))
		if(dest_dir.is_empty()):
			fail("Failed to unzip game","The archive file was unable to be unzipped")
			return ""
			
		#Extract and then validate, because we have to extract first anyway
		var feedback = GameJsonLoadInfo.new()
		print("Testing dir",dest_dir)
		if Globals.load_cards_levels(dest_dir,feedback): #Check root dir first
			return dest_dir
		else:
			for subpath in FileUtils.list_subpaths(dest_dir): #If that doesnt work, check subfolders that were extracted
				if(DirAccess.dir_exists_absolute(subpath)):
					print("Testing dir" , subpath)
					if Globals.load_cards_levels(subpath, feedback):
						return dest_dir
		fail("Unable to load extracted game",feedback.message)
		
	else: #If this is a folder
		var feedback = GameJsonLoadInfo.new()
		if Globals.load_cards_levels(input_dir,feedback): #First validate the game before copying it over
			if(dest_dir != input_dir): #If the destination is different than the temp dir
				info("","Copying game", 0.5)
				if FileUtils.copy_game(input_dir, dest_dir, feedback):
					feedback = GameJsonLoadInfo.new()
					if Globals.load_cards_levels(dest_dir,feedback):
						return dest_dir
					else:
						fail("Unable to load copied game",feedback.message)
				else:
					fail("Unable to load game",feedback.message)
			else:
				return dest_dir
		else:
			fail("Unable to load game",feedback.message)
	return ""


func _on_cancel_button_pressed() -> void:
	self.hide()


func _on_ok_button_pressed() -> void:
	self.hide()
