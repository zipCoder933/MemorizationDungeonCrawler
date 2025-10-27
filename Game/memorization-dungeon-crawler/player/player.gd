extends RigidBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"
const DEATH_ANIMATION = "death Retarget"
const HIT_ANIMATION = ["hit1 Retarget","hit2 Retarget","hit3 Retarget"]

enum PlayerMode{
	ADVENTURE,
	FACTS,
	GAME_OVER, VICTORY
}
#camera
@export var phantom_camera_3d: PhantomCamera3D
var camRotation = Vector3(0, 0, 0)
const cameraSensitivity:float = 4;
var cam_offset:Vector2 = Vector2(0,0)
var target_cam_offset:Vector2 = Vector2(0,0)
#movement
var movement:Vector3 = Vector3.ZERO
var is_on_floor:bool = false
const FORWARD_SPEED = 400

const PLAYER_STEER_MOUSE:bool = false
var targetRotation:float;
var mode = PlayerMode.ADVENTURE

#health
signal health_changed
const MAX_HEALTH = 1
var health:float = 1

func change_health(amt):
	if(amt < 0):
		animation_player.play(HIT_ANIMATION[randi_range(0,HIT_ANIMATION.size()-1)], 0.5, 0.2)
	health = health + amt
	if(health > MAX_HEALTH):
		health = MAX_HEALTH
	if(health <= 0):
		Globals.game_over.emit()
	health_changed.emit(health)

func _ready():
	print("PHANTOM CAMERA ",phantom_camera_3d)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.game_over.connect(_game_over)
	Globals.adventure_mode.connect(_global_adventure_mode)
	Globals.victory.connect(_victory)

var flash_card:WorldFlashCard = null

func _victory():
	mode = PlayerMode.VICTORY
	animation_player.play("Armature|mixamo_com|Layer0_002 Retarget",1)
	mouse_controller.unlock_mouse_forever()

func _game_over():
	mode = PlayerMode.GAME_OVER
	animation_player.play(DEATH_ANIMATION,1)
	mouse_controller.unlock_mouse_forever()

func _global_fact_answering_mode(target2:WorldFlashCard):#target:Vector3
	flash_card = target2
	mode = PlayerMode.FACTS
	animation_player.play(IDLE_ANIMATION,0.5)

func _global_adventure_mode():
	if(health > 0):
		print("Adventure mode")
		mode = PlayerMode.ADVENTURE

func get_normalized_mouse() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var centered_mouse = ((mouse_pos / viewport_size) - Vector2(0.5, 0.5)) * 2.0
	return centered_mouse

@onready var mouse_controller: MouseController = $MouseController

const TURN_SPEED = 4;
const MOUSE_SENSITIVITY = 0.06

func _process(delta:float):
	camRotation.x += -mouse_controller.mouse_delta.y * MOUSE_SENSITIVITY
	camRotation.x = clamp(camRotation.x, -PI/3, PI/3)
	camRotation.y += (-mouse_controller.mouse_delta.x * MOUSE_SENSITIVITY) + (movement.x * delta * TURN_SPEED)
	phantom_camera_3d.set_third_person_rotation(camRotation)

	if(mode == PlayerMode.GAME_OVER):
		pass
	else:
		#Animations
		if(linear_velocity.y > 0.5 ):
			animation_player.play(JUMP_UP_ANIMATION,0.1)
		elif(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
			animation_player.play(RUNNING_ANIMATION,0.1)
		elif(!animation_player.is_playing()):
			animation_player.play(IDLE_ANIMATION,1)


func _physics_process(delta: float) -> void:
	if(mode == PlayerMode.ADVENTURE or mode == PlayerMode.FACTS):
		var forwardDir = transform.basis.z.normalized()  # Godot's "forward" is -Z
		
		#if(mode == PlayerMode.ADVENTURE):
		var forward_movement = max(abs(movement.z),abs(movement.x))
		linear_velocity.x = forwardDir.x * (forward_movement * FORWARD_SPEED * delta)
		linear_velocity.z = forwardDir.z * (forward_movement * FORWARD_SPEED * delta)
		if(movement.z >= 0):
			targetRotation = phantom_camera_3d.get_third_person_rotation().y + PI
		else:
			targetRotation = phantom_camera_3d.get_third_person_rotation().y
		#else: #TODO: ditch this?
			#var forward_movement = max(abs(movement.z),abs(movement.x))
			#linear_velocity.x = forwardDir.x * (movement.z * FORWARD_SPEED * delta)
			#linear_velocity.z = forwardDir.z * (movement.z * FORWARD_SPEED * delta)
			#var target_pos = flash_card.global_position
			#var self_pos = global_transform.origin
			## get direction (ignoring Y)
			#var dir = target_pos - self_pos
			#dir.y = 0
			#dir = dir.normalized()
			#var target_yaw = atan2(dir.x, dir.z)
			#targetRotation = target_yaw
		rotation.y = lerp_angle(rotation.y, targetRotation, 0.05)
	else:
		linear_velocity = Vector3.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if(mode != PlayerMode.GAME_OVER):
			if Input.is_action_just_pressed("Forward"):
				movement.z = 1;
			elif Input.is_action_just_released("Forward"):
				movement.z = 0;
				animation_player.play(IDLE_ANIMATION,1)
				
			if Input.is_action_just_pressed("Backward"):
				movement.z = -1;
				targetRotation = rotation.y+PI;
			elif Input.is_action_just_released("Backward"):
				movement.z = 0;
				animation_player.play(IDLE_ANIMATION,1)
				
			if Input.is_action_just_pressed("Left"):
				movement.x = 1;
				if(movement.z == 0):
					targetRotation = rotation.y+PI/2
			elif Input.is_action_just_released("Left"):
				movement.x = 0;
				animation_player.play(IDLE_ANIMATION,1)
				target_cam_offset.y = rotation.y
				
			if Input.is_action_just_pressed("Right"):
				movement.x = -1;
				if(movement.z == 0):
					targetRotation = rotation.y-PI/2
			elif Input.is_action_just_released("Right"):
				movement.x = 0;
				animation_player.play(IDLE_ANIMATION,1)
				target_cam_offset.y = rotation.y
				
			if is_on_floor == true and Input.is_action_just_pressed("Jump"):
				animation_player.play(JUMP_UP_ANIMATION,1)
				apply_central_impulse(Vector3(0, 10, 0))
				is_on_floor = false
		else:
			movement = Vector3.ZERO

func _on_body_entered(body: Node) -> void:
	if body is Floor:
		print("Floor")
		is_on_floor = true
	elif body is DoorTrigger:
		body.open_door(true)
	elif body is GoblinTrigger:
		body.trigger()
