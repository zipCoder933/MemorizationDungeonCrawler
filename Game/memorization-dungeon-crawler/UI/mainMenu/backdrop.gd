extends Node
@onready var version: Label = %version
@onready var sound_button: Button = %soundButton

func muteSound(is_muted:bool):
	var master_bus := AudioServer.get_bus_index("Master")
	if(is_muted):
		sound_button.text = "Sound: OFF"
	else:
		sound_button.text = "Sound: ON"
		Globals.play_music()
	
	SaveHandler.muted = is_muted
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	AudioServer.set_bus_mute(
		master_bus,
		is_muted
	)

func _ready():
	muteSound(SaveHandler.muted)
	version.text = " v"+ProjectSettings.get_setting("application/config/version")
	if(Globals.is_in_editor()):
		version.text +=" (Editor mode)"


func _on_sound_button_pressed() -> void:
	muteSound(!SaveHandler.muted)
