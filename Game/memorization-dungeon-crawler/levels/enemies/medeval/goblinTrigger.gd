extends StaticBody3D
class_name GoblinTrigger
@onready var _3d_flashcard: WorldFlashCard = $"../3dFlashcard"
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func trigger():
	print("You should not have come")
	
	_3d_flashcard.drill([ 
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level,0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level,0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level,0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level,0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level,0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.5, LevelsHandler.current_level,0.2)
	 ])
