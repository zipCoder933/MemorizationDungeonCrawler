extends Node3D
@onready var card: WorldFlashCard = $Card

func _ready():
	Globals.drill_flashcards(
		[ 
	Question.new(true, "res://data/games/music/images/bass_024_C1.png", "C", 5),
	Question.new(true, "res://data/games/music/images/bass_028_E1.png", "E", 5),
	Question.new(true, "res://data/games/music/images/bass_024_C1.png", "C", 5),
	Question.new(true, "res://data/games/music/images/bass_028_E1.png", "D", 5)
	 ],
	card
	)
