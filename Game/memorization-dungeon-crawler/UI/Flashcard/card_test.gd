extends Node3D
@onready var card: WorldFlashCard = $Card

func _ready():
	card.drill([ 
	Question.new(false, "5+5", "10", 5),
	Question.new(false, "10+10", "20", 5),
	Question.new(false, "15+15", "30", 5),
	Question.new(false, "20+20", "40", 5)
	 ])
