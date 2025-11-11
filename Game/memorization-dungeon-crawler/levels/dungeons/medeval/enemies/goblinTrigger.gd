extends StaticBody3D
class_name GoblinTrigger

const SHRINK_SPEED:float = 0.6
@export var _3d_flashcard: WorldFlashCard
@export var _animation_player: AnimationPlayer
@export var node_3d: Node3D

@onready var player:Player = get_tree().get_first_node_in_group("player");

@export var damage:float = 0.5
@export var speed:float = 0.8
@export var cardNumber:int = 10
@export var idle_animation:String
@export var punch_animation:String
@export var take_hit_animation:String
@export var death_animation:String

var isDead = false
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

func _single_drill(success):
	if(success):
		_animation_player.play(take_hit_animation,0.2)
	else:
		pass
		#_animation_player.play(punch_animation,0.2)

func _finish_drill(success, count):
	if(success > 0):
		Globals.completedArenas += 1
		isDead = true
		_animation_player.play(death_animation,0.2)
		#Refull health
		player.change_health(0.8)

func _ready() -> void:
	_3d_flashcard.signal_flashcard_finished_drill.connect(_finish_drill)
	_3d_flashcard.signal_flashcard_single_drill.connect(_single_drill)

func _process(delta):
	if not is_instance_valid(node_3d):
		return
	
	if !isDead and !_animation_player.is_playing():
		_animation_player.play(idle_animation,0.2)
	
	var target_pos = player.global_position
	var self_pos = global_transform.origin
	
	if isDead: #Point towards the player
		if(!_animation_player.is_playing()):
			node_3d.scale = Vector3(
				node_3d.scale.x - SHRINK_SPEED * delta,
			 	node_3d.scale.y - SHRINK_SPEED * delta, 
				node_3d.scale.z - SHRINK_SPEED * delta)
		if(node_3d.scale.y <= 0): #Delete this node
			node_3d.queue_free()
	else:
		var dir = target_pos - self_pos
		dir.y = 0
		dir = dir.normalized()
		var target_yaw = atan2(dir.x, dir.z)
		node_3d.rotation.y = target_yaw

func trigger():
	if(isDead):
		return
	print("You should not have come")
	
	var questions:Array[Question] = []
	for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, cardNumber):
		questions.append(card.toQuestion(speed, SaveHandler.currentLevel, damage))
	Globals.drill_questions(questions, _3d_flashcard)
