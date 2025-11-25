extends Node
@onready var version: Label = %version

func _ready():
	version.text = " v"+ProjectSettings.get_setting("application/config/version")
