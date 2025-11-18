extends RigidBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"
const DEATH_ANIMATION = "death Retarget"
const FIGHT_IDLE_ANIMATION = "spell Retarget"
const IDLE_ANIMATIONS = ["sword idle Retarget"]
const HIT_ANIMATION = ["hit1 Retarget","hit2 Retarget","hit3 Retarget"]
const VICTORY_ANIMATION = "victory"
var mode:PlayerMode = PlayerMode.ADVENTURE
enum PlayerMode{
	ADVENTURE,
	FACTS,
	STILL, 
	GAME_OVER,
	VICTORY
}

func _is_still():
	return mode == PlayerMode.STILL or mode == PlayerMode.GAME_OVER or mode == PlayerMode.VICTORY\
	 or !mouse_controller.mouse_locked or bossfight_finish_entity != null

#camera
@export var phantom_camera_3d: PhantomCamera3D
var camRotation = Vector3(0, 0, 0)
const cameraSensitivity:float = 4;
var cam_offset:Vector2 = Vector2(0,0)
var target_cam_offset:Vector2 = Vector2(0,0)

#movement
var movement:Vector3 = Vector3.ZERO
var is_on_floor:bool = false
const FORWARD_SPEED = 600
const PLAYER_STEER_MOUSE:bool = false
var targetRotation:float;
var bossfight_finish_entity

#health / status
signal health_changed
const MAX_HEALTH = 1
var health:float = 1
var keys:int = 0

func obtain_key(key:KeyNode):
	keys+=1
	if(SaveHandler.currentLevel.levelType == Level.LevelType.STANDARD):
		if(keys >= Globals.totalArenas):
			Globals.victory_event()
	elif(SaveHandler.currentLevel.levelType == Level.LevelType.BOSS):
		if(key.is_boss_key):
			Globals.victory_event()
	key.queue_free()

func set_health(value:float):
	if(health != value):
		if(health > value):
			print("Hit animation")
			animation_player.play(HIT_ANIMATION[randi_range(0,HIT_ANIMATION.size()-1)], 0.2, 1)
		if(value > MAX_HEALTH):
			health = MAX_HEALTH
		elif(value <= 0):
			health = 0
			Globals.game_over_event()
		else:
			health = value
		health_changed.emit(health)

func change_health(amt:float):
	set_health(health+amt)

func _global_boss_defeated(_boss:GoblinTrigger, accuracy:float):
	bossfight_finish_entity = _boss
	mode = PlayerMode.STILL

func _ready():
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.signal_game_over.connect(_game_over)
	Globals.adventure_mode.connect(_global_adventure_mode)
	Globals.signal_victory.connect(_victory)
	Globals.signal_boss_defeated.connect(_global_boss_defeated)

var flash_card:WorldFlashCard = null

func _victory():
	mode = PlayerMode.VICTORY
	animation_player.play(VICTORY_ANIMATION,1)
	mouse_controller.unlock_mouse_forever()

func _game_over():
	mode = PlayerMode.GAME_OVER
	animation_player.play(DEATH_ANIMATION,1)
	mouse_controller.unlock_mouse_forever()

func _global_fact_answering_mode(target2:WorldFlashCard):#target:Vector3
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	flash_card = target2
	mode = PlayerMode.FACTS
	movement = Vector3.ZERO
	animation_player.play(FIGHT_IDLE_ANIMATION, 0.5)

func _global_adventure_mode():
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	if(health > 0):
		flash_card = null
		mode = PlayerMode.ADVENTURE

func get_normalized_mouse() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var centered_mouse = ((mouse_pos / viewport_size) - Vector2(0.5, 0.5)) * 2.0
	return centered_mouse

@onready var mouse_controller: MouseController = $MouseController

const TURN_SPEED = 4;
const FLASHCARD_MAX_TURN_SPEED = 4
const FLASHCARD_MIN_TURN_SPEED = 0.002
const MOUSE_SENSITIVITY = 0.06

func _process(delta:float):
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	camRotation.x += -mouse_controller.mouse_delta.y * MOUSE_SENSITIVITY
	camRotation.x = clamp(camRotation.x, -PI/3, PI/3)
	camRotation.y += (-mouse_controller.mouse_delta.x * MOUSE_SENSITIVITY) + (movement.x * delta * TURN_SPEED)
	phantom_camera_3d.set_third_person_rotation(camRotation)
	
	if mode == PlayerMode.FACTS and flash_card != null:
		var dir_to_target = (global_position - flash_card.global_position).normalized()
		var target_angle = atan2(dir_to_target.x, dir_to_target.z)  # For 3D (y-rotation)
		var dist = global_position.distance_to(flash_card.global_position)
		var turn_multiplier = clamp(Globals.map(dist, 1, 10, FLASHCARD_MIN_TURN_SPEED, FLASHCARD_MAX_TURN_SPEED),\
												FLASHCARD_MIN_TURN_SPEED, FLASHCARD_MAX_TURN_SPEED)
		camRotation.y = lerp_angle(camRotation.y, target_angle, turn_multiplier * delta)

	if(_is_still()):
		movement = Vector3.ZERO
	else:
		if(mode == PlayerMode.FACTS):
			if(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
				animation_player.play(RUNNING_ANIMATION,0.1)
			elif (abs(movement.x) < 0.01 or abs(movement.z) < 0.01):
				if !animation_player.is_playing() or animation_player.get_current_animation() == RUNNING_ANIMATION:
						animation_player.play(FIGHT_IDLE_ANIMATION,0.21)
		elif(mode == PlayerMode.ADVENTURE):
			if(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
				animation_player.play(RUNNING_ANIMATION,0.1)
			elif (abs(movement.x) < 0.01 or abs(movement.z) < 0.01):
				if Time.get_ticks_msec() - last_movement_time > 10000: #If its been 10 seconds since we moved, play a random idle animation
					animation_player.play(IDLE_ANIMATIONS[randi_range(0,IDLE_ANIMATIONS.size()-1)],0.21)
					last_movement_time = Time.get_ticks_msec()
				elif !animation_player.is_playing() or \
					animation_player.get_current_animation() == RUNNING_ANIMATION:
						animation_player.play(IDLE_ANIMATION,0.21)


func _physics_process(delta: float) -> void:
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	if(_is_still()):
		linear_velocity = Vector3.ZERO
	else:
		var forwardDir = transform.basis.z.normalized()  # Godot's "forward" is -Z
		var forward_movement = max(abs(movement.z),abs(movement.x))
		var speed = FORWARD_SPEED
		
		#We dont want the player to wander too far away from the flashcard and cheat
		if(mode == PlayerMode.FACTS and flash_card !=null):
			var dir_to_target = (flash_card.global_position - global_position).normalized()
			var alignment = dir_to_target.dot(forwardDir)
			#print("alignment ",alignment)
			# alignmenwwt = 1 → moving straight toward target
			# alignment = -1 → moving straight away
			if alignment < 0:
				var dist = global_position.distance_to(flash_card.global_position)
				speed = clamp(Globals.map(dist, 0, 5, FORWARD_SPEED ,0),0,FORWARD_SPEED)

		
		linear_velocity.x = forwardDir.x * (forward_movement * speed * delta)
		linear_velocity.z = forwardDir.z * (forward_movement * speed * delta)
		if(movement.z >= 0):
			targetRotation = phantom_camera_3d.get_third_person_rotation().y + PI
		else:
			targetRotation = phantom_camera_3d.get_third_person_rotation().y
		rotation.y = lerp_angle(rotation.y, targetRotation, 0.05)
		
var last_movement_time:int  = 0;

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var canUseWASD:bool = mode != PlayerMode.FACTS
		if(event.pressed):
			if(not _is_still()):
				if Input.is_action_just_pressed("Forward") or (canUseWASD and event.keycode == KEY_W):
					movement.z = 1;
					last_movement_time = Time.get_ticks_msec()
				elif Input.is_action_just_pressed("Backward")  or (canUseWASD and event.keycode == KEY_S):
					movement.z = -1;
					last_movement_time = Time.get_ticks_msec()
					targetRotation = rotation.y+PI;
				elif Input.is_action_just_pressed("Left")  or (canUseWASD and event.keycode == KEY_A):
					movement.x = 1;
					last_movement_time = Time.get_ticks_msec()
					if(movement.z == 0):
						targetRotation = rotation.y+PI/2
				elif Input.is_action_just_pressed("Right")  or (canUseWASD and event.keycode == KEY_D):
					movement.x = -1;
					last_movement_time = Time.get_ticks_msec()
					if(movement.z == 0):
						targetRotation = rotation.y-PI/2
		else:
			if Input.is_action_just_released("Forward")  or (event.keycode == KEY_W):
				movement.z = 0;
			elif Input.is_action_just_released("Backward")  or (event.keycode == KEY_S):
				movement.z = 0;
			elif Input.is_action_just_released("Left")  or (event.keycode == KEY_A):
				movement.x = 0;
				target_cam_offset.y = rotation.y
			elif Input.is_action_just_released("Right")  or (event.keycode == KEY_D):
				movement.x = 0;
				target_cam_offset.y = rotation.y
			#If we were running
			if(not _is_still() and animation_player.get_current_animation() == RUNNING_ANIMATION):
				if(abs(movement.x) < 0.01 or abs(movement.z) < 0.01):
					if( mode ==PlayerMode.ADVENTURE):
						animation_player.play(IDLE_ANIMATION,0.21)
					elif(mode == PlayerMode.FACTS):
						animation_player.play(FIGHT_IDLE_ANIMATION,0.21)

func _on_body_entered(body: Node) -> void:
	if body is FloorCeiling:
		is_on_floor = true
	elif body is DoorTrigger:
		body.open_door(true)
	elif body is GoblinTrigger:
		body.trigger()
	elif body is KeyTrigger:
		obtain_key(body.get_key())
