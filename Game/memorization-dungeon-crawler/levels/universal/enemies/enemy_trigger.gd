extends StaticBody3D
class_name GoblinTrigger
const SHRINK_SPEED:float = 1.8
@export var _3d_flashcard: WorldFlashCard
@export var _animation_player: AnimationPlayer
@export var root_node: Node3D
@onready var player:Player = get_tree().get_first_node_in_group("player");
@export var enemy_model:Node
@export var collision_shape_3d:CollisionShape3D
@export var fail_health_add:float = -0.5
@export var success_health_add:float = 0
@export var speed:float = 0.8
@export var cardNumber:int = 10

#Animaitons
@export var idle_animation:String
@export var idle_animation_speed:float = 1
@export var fight_idle_animation:String
@export var punch_animation:String
@export var take_hit_animation:String
@export var take_hit_animation_speed:float = 1
@export var death_animation:String

@export var begin_delay = 1
@export var is_boss = false

var fighting = false
var isDead = false
var timeOfDeath:int;
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

var accuracy:Array[float] = []

func ready():
	_animation_player.play(idle_animation,0.2,idle_animation_speed)

func _single_drill(success):
	if(success):
		accuracy.append(100)
		player.change_health(success_health_add)
		if(take_hit_animation != null):
			_animation_player.play(take_hit_animation,0.2,take_hit_animation_speed)
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
	timeOfDeath = Time.get_ticks_msec()
	if(is_instance_valid(root_node) && death_animation != null):
		_animation_player.play(death_animation,0.2)

func _victory_event():
	die()

func _ready() -> void:
	_3d_flashcard.signal_flashcard_finished_drill.connect(_finish_drill)
	_3d_flashcard.signal_flashcard_single_drill.connect(_single_drill)
	Globals.signal_victory.connect(_victory_event)

func _process(delta):
	if(is_boss):
		if(Globals.get_player().keys < Globals.totalArenas and !Engine.is_embedded_in_editor()):
			enemy_model.visible=false
			collision_shape_3d.disabled = true
		else:
			enemy_model.visible=true
			collision_shape_3d.disabled=false
	
	if not is_instance_valid(root_node):
		return
	
	var target_pos = player.global_position
	var self_pos = global_transform.origin
	
	if isDead: #Point towards the player
		if(!_animation_player.is_playing() or Time.get_ticks_msec()-timeOfDeath > 2000):
			root_node.scale = Vector3(
				root_node.scale.x - SHRINK_SPEED * delta,
			 	root_node.scale.y - SHRINK_SPEED * delta, 
				root_node.scale.z - SHRINK_SPEED * delta)
		if(root_node.scale.y <= 0): #Delete this node
			var p = Vector3(root_node.global_position.x,root_node.global_position.y,root_node.global_position.z)
			if(!is_boss):
				Globals.spawn_potion(p)
			Globals.spawn_key(p,is_boss)
			root_node.queue_free()
	else:  #If not dead
		if !_animation_player.is_playing():#Play idle animation
			if(fighting and fight_idle_animation != null):
				_animation_player.play(fight_idle_animation,0.2,idle_animation_speed)
			else:
				_animation_player.play(idle_animation,0.2,idle_animation_speed)
		var dir = target_pos - self_pos
		dir.y = 0
		dir = dir.normalized()
		var target_yaw = atan2(dir.x, dir.z)
		enemy_model.rotation.y = target_yaw

func trigger():
	if(isDead):
		return
	var questions:Array[Question] = []
	fighting=true
	
	if(fight_idle_animation !=null):
		_animation_player.play(fight_idle_animation,0.2,idle_animation_speed)
	
	if(is_boss):
		for i in range(0,cardNumber):#We want to go through the entire deck X times
			for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, 0):
				questions.append(card.toQuestion(speed, SaveHandler.currentLevel))
	else:
		for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, cardNumber):
			questions.append(card.toQuestion(speed, SaveHandler.currentLevel))
	
	print("Drilling player on deck; size: ",questions.size(),"; tags: ",SaveHandler.currentLevel.card_tags)
	Globals.drill_questions(questions, _3d_flashcard, begin_delay)
