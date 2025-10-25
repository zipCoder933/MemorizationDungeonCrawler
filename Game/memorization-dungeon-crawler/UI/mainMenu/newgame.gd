extends Control

func _on_cancel_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/mainMenu/main_menu.tscn")
