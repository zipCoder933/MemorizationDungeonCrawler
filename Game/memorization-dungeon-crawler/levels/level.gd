extends Node3D
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func _ready():
	var dir = "res://data/games/multiplication/"
	CardsHandler.load_from_file(dir+"/cards.json")
	LevelsHandler.load_from_file(dir+"/level.json")
	LevelsHandler.current_level = LevelsHandler.levels[0]
	
