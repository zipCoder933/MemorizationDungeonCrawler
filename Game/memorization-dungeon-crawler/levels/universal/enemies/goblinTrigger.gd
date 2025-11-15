extends StaticBody3D
class_name GoblinTrigger

const SHRINK_SPEED:float = 1.8
@export var _3d_flashcard: WorldFlashCard
@export var _animation_player: AnimationPlayer
@export var node_3d: Node3D

@onready var player:Player = get_tree().get_first_node_in_group("player");

@export var fail_health_add:float = -0.5
@export var success_health_add:float = 0
@export var speed:float = 0.8
@export var cardNumber:int = 10
@export var idle_animation:String
@export var punch_animation:String
@export var take_hit_animation:String
@export var death_animation:String
@export var begin_delay = 1
@export var is_boss = false

var isDead = false
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

var accuracy:Array[float] = []

func _single_drill(success):
	if(success):
		accuracy.append(100)
		player.change_health(success_health_add)
		_animation_player.stop()
		_animation_player.play(take_hit_animation,0.2)
	else:
		accuracy.append(0)
		player.change_health(fail_health_add)

func _finish_drill(success, count):
	if(is_boss):
		var total_accuracy_score:float = 0
		for val in accuracy:
			total_accuracy_score += val
		total_accuracy_score = total_accuracy_score / accuracy.size()
		print("Bossfight finished. Accuracy ",total_accuracy_score)
		Globals.boss_defeated_event(self, total_accuracy_score)
	else:
		if(success > 0):
			die()

func die():
	isDead = true
	if(is_instance_valid(node_3d)):
		_animation_player.play(death_animation,0.2)

func _victory_event():
	die()

func _ready() -> void:
	_3d_flashcard.signal_flashcard_finished_drill.connect(_finish_drill)
	_3d_flashcard.signal_flashcard_single_drill.connect(_single_drill)
	Globals.signal_victory.connect(_victory_event)

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
			var p = Vector3(node_3d.global_position.x,node_3d.global_position.y,node_3d.global_position.z)
			if(!is_boss):
				Globals.spawn_potion(p)
			Globals.spawn_key(p,is_boss)
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
	var questions:Array[Question] = []
	
	if(is_boss):
		for i in range(0,cardNumber):#We want to go through the entire deck X times
			for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, 0):
				questions.append(card.toQuestion(speed, SaveHandler.currentLevel))
	else:
		for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, cardNumber):
			questions.append(card.toQuestion(speed, SaveHandler.currentLevel))
	
	print("Drilling player on deck; size: ",questions.size(),"; tags: ",SaveHandler.currentLevel.card_tags)
	Globals.drill_questions(questions, _3d_flashcard, begin_delay)
