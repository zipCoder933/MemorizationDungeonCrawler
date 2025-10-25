extends StaticBody3D
class_name GoblinTrigger

@onready var _3d_flashcard: WorldFlashCard = $"../3dFlashcard"
@onready var _animation_player: AnimationPlayer = $"../AnimationPlayer"

const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func playdeathanimation(success, count):
	if _animation_player and _animation_player.has_animation("Death Retarget"):
		_animation_player.play("Death Retarget")	

func _ready() -> void:
	if _animation_player and _animation_player.has_animation("Idle Retarget"):
		_animation_player.play("Idle Retarget")
	_3d_flashcard.finished_drill.connect(playdeathanimation)

func trigger():
	print("You should not have come")
	
	_3d_flashcard.drill([
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.5, LevelsHandler.current_level, 0.2)
	])
