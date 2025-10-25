extends Node3D
const SaveHandler = preload("uid://bgwdh30vglopu")


func _ready():
	SaveHandler.load_from_file(Globals.SAVE_FILE)
	Globals.start_game(SaveHandler.saves[0], false)
