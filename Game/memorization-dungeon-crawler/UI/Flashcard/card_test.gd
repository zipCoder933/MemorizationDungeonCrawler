extends Node3D
@onready var card: WorldFlashCard = $Card
const CardsHandler = preload("uid://cc0wwewiey4d7")
const SaveHandler = preload("uid://bgwdh30vglopu")



func _ready():
	CardsHandler.load_from_file("res://data/games/multiplication/cards.json")

	print("\n\nCARDS")
	for card in CardsHandler.get_random_cards(["1s","2s"],0):
		print("CARD ",card.toString())
	
	#Globals.drill_flashcards(
		#[ 
	#Question.new(true, "res://data/games/music/images/bass_024_C1.png", "C", 5),
	#Question.new(true, "res://data/games/music/images/bass_028_E1.png", "E", 5),
	#Question.new(true, "res://data/games/music/images/bass_024_C1.png", "C", 5),
	#Question.new(true, "res://data/games/music/images/bass_028_E1.png", "D", 5)
	 #],
	#card
	#)
