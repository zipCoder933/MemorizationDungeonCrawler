extends StaticBody3D
class_name GoblinTrigger

@onready var _3d_flashcard: WorldFlashCard = $"../3dFlashcard"
@onready var _animation_player: AnimationPlayer = $"../AnimationPlayer"

var isDead = false
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func _single_drill(success):
	if(success):
		_animation_player.play("TakeHit Retarget",0.2)

func _finish_drill(success, count):
	isDead = true
	_animation_player.play("Death Retarget",0.2)

func _ready() -> void:
	_3d_flashcard.finished_drill.connect(_finish_drill)
	_3d_flashcard.single_drill.connect(_single_drill)

func _process(delta):
	if !isDead and !_animation_player.is_playing():
		_animation_player.play("Idle Retarget")

func trigger():
	if(isDead):
		return
	print("You should not have come")

	_3d_flashcard.drill([
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(1, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.7, LevelsHandler.current_level, 0.2),
		CardsHandler.randomCardInCurrentLevel().toQuestion(0.5, LevelsHandler.current_level, 0.2)
	])
