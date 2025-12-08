extends StaticBody3D
class_name GoblinTrigger
const SHRINK_SPEED:float = 1.5
@export var _3d_flashcard: WorldFlashCard
@export var _animation_player: AnimationPlayer
@export var root_node: Node3D
@onready var player:Player = get_tree().get_first_node_in_group("player");
@export var enemy_model:Node
@export var collision_shape_3d:CollisionShape3D
var fail_health_add:float;
var success_health_add:float;

#Animaitons
@export var idle_animation:String
@export var idle_animation_speed:float = 1
@export var fight_idle_animation:String
@export var fight_idle_animation_speed:float = 1
@export var punch_animation:String
@export var take_hit_animation:String
@export var take_hit_animation_speed:float = 1
@export var death_animation:String

@export var begin_delay = 1
@export var is_boss = false

var fighting = false
var isDead = false
var timeOfDeath:int;
var death_animation_finished:bool = false
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")


func _ready():
	_3d_flashcard.signal_flashcard_finished_drill.connect(_finish_drill)
	_3d_flashcard.signal_flashcard_single_drill.connect(_single_drill)
	Globals.signal_victory.connect(_victory_event)
	
	_animation_player.play(idle_animation,0.2,idle_animation_speed)
	_animation_player.animation_finished.connect(_animation_finished)
	_animation_player.animation_started.connect(_animation_started)
	_animation_player.animation_changed.connect(_animation_changed)
	
	if(is_boss):
		fail_health_add = -0.10
		success_health_add = 0.05
	else:
		fail_health_add = -0.30
		success_health_add = 0.05
	#if(take_hit_animation != null):
		#var anim = _animation_player.get_animation(take_hit_animation)
		#print("take hit animation loop mode: ", anim.loop_mode)

func _animation_started(animName: StringName):
	#print("Started animation: ", animName)
	pass

func _animation_changed(animName:StringName):
	#print("Changed animation: ",animName)
	pass

func _animation_finished(animName:StringName):
	#print("Finished animation: ",animName)
	if animName == death_animation:
		death_animation_finished = true
	
	if !isDead and animName != idle_animation and animName != fight_idle_animation:
		play_idle_animation()

func play_idle_animation():
	if(fighting and fight_idle_animation != null):
		_animation_player.play(fight_idle_animation,0.4,fight_idle_animation_speed)
	else:
		_animation_player.play(idle_animation,0.4,idle_animation_speed)

func _single_drill(success):
	if(success):
		player.change_health(success_health_add)
		if(!isDead && take_hit_animation != null):
			print("Playing take hit animation...")
			_animation_player.play(take_hit_animation,0.2,take_hit_animation_speed,false)
			_animation_player.seek(0, true)
	else:
		player.change_health(fail_health_add)

func _finish_drill(results:FlashcardDrillResults):
	if(is_boss):
		Globals.boss_defeated_event(self, results)
	else:
		if(results.succeeded > 0):
			#Increment our safety net by our accuracy
			var fill = Globals.map(results.get_accuracy(), 0.5, 1,  0, player.health2_fill)
			player.change_health2(fill)
			die()

func die():
	if(isDead):
		return #We already died
	isDead = true
	timeOfDeath = Time.get_ticks_msec()
	if(is_instance_valid(root_node) && death_animation != null):
		_animation_player.play(death_animation,0.7)

func _victory_event():
	die()


func _process(delta):
	if not is_instance_valid(root_node) or not is_instance_valid(enemy_model):
		return
	
	var target_pos = player.global_position
	var self_pos = global_transform.origin
	
	if isDead: #Point towards the player
		if(death_animation_finished or Time.get_ticks_msec()-timeOfDeath > 2500):
			enemy_model.scale = Vector3(
				enemy_model.scale.x - SHRINK_SPEED * delta,
			 	enemy_model.scale.y - SHRINK_SPEED * delta, 
				enemy_model.scale.z - SHRINK_SPEED * delta)
		if(enemy_model.scale.y <= 0): #Delete this node
			var p = Vector3(enemy_model.global_position.x,
							enemy_model.global_position.y,
							enemy_model.global_position.z)
			if(is_boss):
				enemy_model.queue_free()  #We dont want to erase the boss arena!
			else:
				#Globals.spawn_potion(p)
				Globals.spawn_key(p,is_boss)
				root_node.queue_free()
	else:  #If not dead
		if(is_boss):
			if Engine.is_embedded_in_editor():
				enemy_model.visible=true
				collision_shape_3d.disabled=false
			elif(Globals.get_player().keys < Globals.totalArenas):
				enemy_model.visible=false
				collision_shape_3d.disabled = true
			else:
				enemy_model.visible=true
				collision_shape_3d.disabled=false
		
		if(is_instance_valid(_animation_player) and !_animation_player.is_playing()):
			play_idle_animation()
		var dir = target_pos - self_pos
		dir.y = 0
		dir = dir.normalized()
		var target_yaw = atan2(dir.x, dir.z)
		enemy_model.rotation.y = target_yaw

func trigger():
	if(isDead):
		return
		
	if SaveHandler.currentLevel != null:
		var questions:Array[Question] = []
		fighting=true
		
		if(is_boss):
			var SPEED_MULTIPLIER = 1.0
			for i in range(0, SaveHandler.currentLevel.boss_card_count_multiplier):#We want to go through the entire deck X times
				for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, 0):
					questions.append(card.toQuestion(SPEED_MULTIPLIER, SaveHandler.currentLevel))
		else:
			var SPEED_MULTIPLIER = 1.0
			for card in CardsHandler.get_random_cards(SaveHandler.currentLevel.card_tags, SaveHandler.currentLevel.enemy_card_count):
				questions.append(card.toQuestion(SPEED_MULTIPLIER, SaveHandler.currentLevel))
		
		print("Drilling player on deck; size: ",questions.size(),"; tags: ",SaveHandler.currentLevel.card_tags)
		Globals.drill_questions(questions, _3d_flashcard, begin_delay)
		if(fight_idle_animation !=null):
			_animation_player.play(fight_idle_animation,0.7,idle_animation_speed)
