extends RigidBody3D
class_name Player
@onready var phantom_camera_follow_node: PhantomCameraFollowNode = %PhantomCameraFollowNode

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const RUNNING_ANIMATION_SPEED = 1.15
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"
const DEATH_ANIMATION = "death Retarget"
const FIGHT_IDLE_ANIMATION = "spell Retarget"
const IDLE_ANIMATIONS = ["sword idle Retarget"]
const HIT_ANIMATION = ["hit1 Retarget","hit2 Retarget","hit3 Retarget"]
const VICTORY_ANIMATION = "victory"
var mode:PlayerMode = PlayerMode.ADVENTURE

#Sounds
@onready var drill_submit: AudioStreamPlayer = %drill_submit
@onready var damage_sound: AudioStreamPlayer = %damageSound
@onready var kill_sound: AudioStreamPlayer = %killSound
@onready var success_sound: AudioStreamPlayer = %successSound
@onready var running_sound: AudioStreamPlayer = %runningSound
@onready var drill_fail: AudioStreamPlayer = %drill_fail


enum PlayerMode{
	ADVENTURE, #0
	FACTS, #1
	STILL,  #2
	GAME_OVER,
	VICTORY
}

func _is_still():
	return mode == PlayerMode.STILL or mode == PlayerMode.GAME_OVER or mode == PlayerMode.VICTORY\
	 or !mouse_controller.mouse_locked or bossfight_finish_entity != null

#Called from global for instant playback
func play_submit_sound(succeed:bool):
	if(succeed):
		drill_submit.play(0.01)
	else:
		drill_fail.play(0)


#camera
@export var phantom_camera_3d: PhantomCamera3D
var camRotation = Vector3(0, 0, 0)
const cameraSensitivity:float = 4;
var cam_offset:Vector2 = Vector2(0,0)
var target_cam_offset:Vector2 = Vector2(0,0)

#movement
var movement:Vector3 = Vector3.ZERO
var is_on_floor:bool = false
const FORWARD_SPEED = 700
const PLAYER_STEER_MOUSE:bool = false
var targetRotation:float;
var bossfight_finish_entity

#health / status
signal health_changed
signal signal_health2_changed
signal signal_key_obtained

const MAX_HEALTH = 1

#How much health2 is taken to restore us when our health runs out
var health2_increment:float = 0.33
#How much health is filled when we defeat an enemy
var health2_fill:float = 0.25

var health:float = 1
var health2:float = 0
var keys:int = 0

@onready var sword_mesh: MeshInstance3D = $Knight2/Knight/Skeleton3D/sword
@onready var shield_mesh: MeshInstance3D = $Knight2/Knight/Skeleton3D/shield
@onready var helmet_mesh: MeshInstance3D = $Knight2/Knight/Skeleton3D/helmet
@onready var body_mesh: MeshInstance3D = $Knight2/Knight/Skeleton3D/body


func _ready():
	print("Health increment: ",health2_increment)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.signal_game_over.connect(_game_over)
	Globals.adventure_mode.connect(_global_adventure_mode)
	Globals.signal_victory.connect(_victory)
	Globals.signal_show_bossfight_results.connect(_global_boss_defeated)
	
	#success_sound.play(0)

#Set phantom camera default parameters
	#https://phantom-camera.dev/follow-modes/overview
	#Follow mode should not change
	phantom_camera_3d.follow_mode = PhantomCamera3D.FollowMode.THIRD_PERSON
	phantom_camera_3d.follow_target = phantom_camera_follow_node
	phantom_camera_3d.look_at_mode = PhantomCamera3D.LookAtMode.NONE
	phantom_camera_3d.follow_damping = false
	phantom_camera_3d.tween_on_load = false
	phantom_camera_3d.spring_length = phantom_camera_follow_node.length


func set_alpha(transparent:bool):
	if(transparent):
		_set_mesh_alpha(body_mesh, 0.6)
		_set_mesh_alpha(sword_mesh, 0.5)
		_set_mesh_alpha(shield_mesh, 0.5)
		_set_mesh_alpha(helmet_mesh, 0.95)
	else:
		_set_mesh_alpha(body_mesh, 1)
		_set_mesh_alpha(sword_mesh, 1)
		_set_mesh_alpha(shield_mesh, 1)
		_set_mesh_alpha(helmet_mesh, 1)

func _set_mesh_alpha(mesh: MeshInstance3D, alpha: float):
	var mat := mesh.get_active_material(0)
	if mat:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
		var c:Color = mat.albedo_color
		c.a = alpha
		mat.albedo_color = c
		
		if(alpha <= 0):
			mesh.visible = false
		elif(alpha >= 1):
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			mesh.visible = true
		else:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.alpha_cutoff = 0.2      # anything below is discarded
			mat.albedo_color = Color(1, 1, 1, alpha)   # partially see-through
			mat.cull_mode = BaseMaterial3D.CULL_BACK
			mat.depth_draw_mode = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			mesh.visible = true


func obtain_key(key:KeyNode):
	keys+=1
	signal_key_obtained.emit(keys)
	change_health(0.6)
	#change_health2(health2_increment)
	if(SaveHandler.get_current_level().levelType == Level.LevelType.STANDARD):
		if(keys >= Globals.totalArenas):
			Globals.victory_event()
	#elif(SaveHandler.get_current_level().levelType == Level.LevelType.BOSS):
		#if(key.is_boss_key):
			#Globals.victory_event()
	success_sound.play(0)
	if(key != null):
		key.queue_free()

func set_health(value:float):
	var last_health = health
	
	if(health > value):
		animation_player.play(HIT_ANIMATION[randi_range(0,HIT_ANIMATION.size()-1)], 0.2, 2)
		damage_sound.play(0)
	if(value > MAX_HEALTH):
		health = MAX_HEALTH
	elif(value <= 0):
		health = 0
		
		#If we have at least 0.5% in our health backup
		if(health2 > 0.005): #Fill the equivalent of the health 2 increment left
			var backup_health = clamp(Globals.map(health2,0,health2_increment,0,1),0,1)
			print("Restoring health by ",backup_health)
			change_health2(-health2_increment)
			health = clamp(health+backup_health,0,MAX_HEALTH)
		
		#If health is still 0 or lower than 0.1%
		if(health <= 0.001):
			Globals.game_over_event()
	else:
		health = value
	
	if(last_health != health):
		health_changed.emit(health)

func set_health2(value:float):
	if(health2 != value):
		if(value > MAX_HEALTH):
			health2 = MAX_HEALTH
		elif(value <= 0):
			health2 = 0
		else:
			health2 = value
		signal_health2_changed.emit(health2)

func change_health(amt:float):
	#print("CHANGING HEALTH BY ",amt)
	set_health(health+amt)

func change_health2(amt:float):
	#print("CHANGING HEALTH2 BY ",amt)
	set_health2(health2+amt)

func _global_boss_defeated(_boss:GoblinTrigger, results:FlashcardDrillResults):
	bossfight_finish_entity = _boss
	mode = PlayerMode.STILL



var flash_card:WorldFlashCard = null

func _victory():
	if(mode != PlayerMode.VICTORY):
		mode = PlayerMode.VICTORY
		animation_player.play(VICTORY_ANIMATION,1)
		phantom_camera_follow_node.flashcard = null
		set_alpha(false)
		mouse_controller.unlock_mouse_forever()


func _game_over():
	if(mode != PlayerMode.GAME_OVER):
		damage_sound.stop()
		kill_sound.play(0)
		animation_player.play(DEATH_ANIMATION, 0.2)
		set_alpha(false)
		phantom_camera_follow_node.flashcard = null
		mode = PlayerMode.GAME_OVER
		mouse_controller.unlock_mouse_forever()

func _global_fact_answering_mode(target2:WorldFlashCard):#target:Vector3
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		set_alpha(false)
		return
	flash_card = target2
	phantom_camera_3d.look_at_targets = [self,target2]
	phantom_camera_follow_node.flashcard = target2
	mode = PlayerMode.FACTS
	movement = Vector3.ZERO
	set_alpha(true)
	animation_player.play(FIGHT_IDLE_ANIMATION, 0.5)

func _global_adventure_mode():
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		set_alpha(false)
		return
	if(health > 0):
		phantom_camera_3d.look_at_targets = []
		phantom_camera_follow_node.flashcard = null
		flash_card = null
		set_alpha(false)
		mode = PlayerMode.ADVENTURE

func get_normalized_mouse() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var centered_mouse = ((mouse_pos / viewport_size) - Vector2(0.5, 0.5)) * 2.0
	return centered_mouse

@onready var mouse_controller: MouseController = $MouseController

const TURN_SPEED = 4;
const FLASHCARD_MAX_TURN_SPEED = 6
const FLASHCARD_MIN_TURN_SPEED = .75
const MOUSE_SENSITIVITY = 0.06
const CAMERA_FLASHCARD_MOVE_DEG = 20.0

func _process(delta:float):
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	camRotation.x += -mouse_controller.mouse_delta.y * MOUSE_SENSITIVITY
	camRotation.x = clamp(camRotation.x, -PI/3, PI/3)
	camRotation.y += (-mouse_controller.mouse_delta.x * MOUSE_SENSITIVITY) + (movement.x * delta * TURN_SPEED)
	phantom_camera_3d.set_third_person_rotation(camRotation)
	phantom_camera_3d.spring_length = phantom_camera_follow_node.length
	
	if mode == PlayerMode.FACTS and flash_card != null:
		var dir_to_target = Vector3(flash_card.global_position - global_position).normalized()
		
		var target_angle = atan2(dir_to_target.x, dir_to_target.z) + PI  # Y-rotation
		
		#Combine the angle of the card and player to the angle of the card itself
		target_angle = lerp_angle(target_angle, flash_card.global_rotation.y, 0.7)
		#print("Target angle: ",target_angle)
		
		var angle_diff = wrapf(target_angle - camRotation.y, -PI, PI)
		var threshold = deg_to_rad(CAMERA_FLASHCARD_MOVE_DEG) #We can be X degrees to the left or right without being bothered
		#Move the camera towards the flashcard if we are pointing the wrong direction
		if abs(angle_diff) > threshold:
			var desired_angle = camRotation.y + (angle_diff - sign(angle_diff) * threshold)
			var dist = global_position.distance_to(flash_card.global_position)
			var turn_multiplier = clamp(
				Globals.map(dist, 1, 10, FLASHCARD_MIN_TURN_SPEED, FLASHCARD_MAX_TURN_SPEED),
				FLASHCARD_MIN_TURN_SPEED, FLASHCARD_MAX_TURN_SPEED)
			camRotation.y = lerp_angle(camRotation.y, desired_angle, turn_multiplier * delta)


	if(_is_still()):
		movement = Vector3.ZERO
	else:
		if(mode == PlayerMode.FACTS):
			if(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
				animation_player.play(RUNNING_ANIMATION,0.1,RUNNING_ANIMATION_SPEED)
			elif (abs(movement.x) < 0.01 or abs(movement.z) < 0.01):
				if !animation_player.is_playing() or animation_player.get_current_animation() == RUNNING_ANIMATION:
						animation_player.play(FIGHT_IDLE_ANIMATION,0.21)
		elif(mode == PlayerMode.ADVENTURE):
			if(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
				animation_player.play(RUNNING_ANIMATION,0.1,RUNNING_ANIMATION_SPEED)
			elif (abs(movement.x) < 0.01 or abs(movement.z) < 0.01):
				if Time.get_ticks_msec() - last_movement_time > 10000: #If its been 10 seconds since we moved, play a random idle animation
					animation_player.play(IDLE_ANIMATIONS[randi_range(0,IDLE_ANIMATIONS.size()-1)],0.21)
					last_movement_time = Time.get_ticks_msec()
				elif !animation_player.is_playing() or \
					animation_player.get_current_animation() == RUNNING_ANIMATION:
						animation_player.play(IDLE_ANIMATION,0.21)

func fade_out(player: AudioStreamPlayer, time := 0.3):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80, time)
	tween.tween_callback(player.stop)


func _physics_process(delta: float) -> void:
	if(mode == PlayerMode.GAME_OVER || mode == PlayerMode.VICTORY):
		return
	if(_is_still()):
		linear_velocity = Vector3.ZERO
	else:
		var forwardDir = transform.basis.z.normalized()  # Godot's "forward" is -Z
		var forward_movement = max(abs(movement.z),abs(movement.x))
		var speed = FORWARD_SPEED
		
		if(forward_movement <= 0.001):
			fade_out(running_sound)
		elif(!running_sound.playing):
			running_sound.volume_db = 0
			running_sound.play()
			#var tween = create_tween()
			#tween.tween_property(player, "volume_db", 0, time)  # ramp up to 0 dB

		
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
