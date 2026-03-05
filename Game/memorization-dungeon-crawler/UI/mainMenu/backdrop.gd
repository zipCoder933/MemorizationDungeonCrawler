extends Node
@onready var version: Label = %version

func _ready():
	version.text = " v"+ProjectSettings.get_setting("application/config/version")
	if(Globals.is_in_editor()):
		version.text +=" (Editor mode)"
