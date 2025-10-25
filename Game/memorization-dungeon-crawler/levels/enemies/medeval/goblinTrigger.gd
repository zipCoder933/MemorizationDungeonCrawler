extends StaticBody3D
class_name GoblinTrigger

@onready var _3d_flashcard: WorldFlashCard = %"3dFlashcard"
@onready var _animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var player:Player = get_tree().get_first_node_in_group("player");
@onready var node_3d: Node3D = $"../Node3D"

var isDead = false
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func _single_drill(success):
	if(success):
		_animation_player.play("TakeHit Retarget",0.2)

func _finish_drill(success, count):
	if(success > 0):
		isDead = true
		_animation_player.play("Death Retarget",0.2)
		#Refull health
		player.change_health(10)

func _ready() -> void:
	_3d_flashcard.finished_drill.connect(_finish_drill)
	_3d_flashcard.single_drill.connect(_single_drill)

func _process(delta):
	if !isDead and !_animation_player.is_playing():
		_animation_player.play("Idle Retarget")
	
	var target_pos = player.global_position
	var self_pos = global_transform.origin
	var dir = target_pos - self_pos
	dir.y = 0
	dir = dir.normalized()
	var target_yaw = atan2(dir.x, dir.z)
	node_3d.rotation.y = target_yaw

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
