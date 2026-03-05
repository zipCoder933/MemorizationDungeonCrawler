extends Node

func _ready():
	if !Engine.is_editor_hint():
		call_deferred("_go_fullscreen")

func _go_fullscreen():
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
