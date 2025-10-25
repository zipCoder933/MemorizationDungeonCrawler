extends RigidBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"
const DEATH_ANIMATION = "death Retarget"
const HIT_ANIMATION = ["hit1 Retarget", "hit2 Retarget", "hit3 Retarget"]

enum PlayerMode{
	ADVENTURE,
	FACTS,
	GAME_OVER
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
const FORWARD_SPEED = 300
const TURN_SPEED = 2;
const PLAYER_STEER_MOUSE:bool = false
var targetRotation:float;
var mode = PlayerMode.ADVENTURE

#health
signal health_changed
const MAX_HEALTH = 1
var health:float = 1

func change_health(amt):
	if(amt < 0):
		animation_player.play(HIT_ANIMATION[randi_range(0,HIT_ANIMATION.size()-1)],0.1, 3.0)
	health = health + amt
	if(health > MAX_HEALTH):
		health = MAX_HEALTH
	if(health < 0):
		Globals.game_over.emit()
	health_changed.emit(health)

func _ready():
	print("PHANTOM CAMERA ",phantom_camera_3d)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.game_over.connect(_game_over)
	Globals.adventure_mode.connect(_global_adventure_mode)

var flash_card:WorldFlashCard = null

func _game_over():
	mode = PlayerMode.GAME_OVER
	animation_player.play(DEATH_ANIMATION,1)

func _global_fact_answering_mode(target2:WorldFlashCard):#target:Vector3
	flash_card = target2
	print("Fact mode ",flash_card)
	mode = PlayerMode.FACTS

func _global_adventure_mode():
	if(health > 0):
		print("Adventure mode")
		mode = PlayerMode.ADVENTURE

func _process(delta:float):
	if(mode == PlayerMode.GAME_OVER): #GAME OVER
		linear_velocity = Vector3.ZERO
		position = flash_card.position
		rotation.y = flash_card.rotation.y
	elif(mode == PlayerMode.FACTS): #FACTS
		if(!animation_player.is_playing()):
			animation_player.play(IDLE_ANIMATION,1)
	else: #ADVENTURE
		#Use the arrow keys to move the camera back and fourth
		cam_offset.y += movement.x * TURN_SPEED * delta;
		camRotation.y = cam_offset.y;
		camRotation.x = -0.349 + cam_offset.x;
		phantom_camera_3d.set_third_person_rotation(camRotation)
		#ROTATION
		rotation.y = phantom_camera_3d.get_third_person_rotation().y + PI
		#Animations
		if( linear_velocity.y > 0.5 ):
			animation_player.play(JUMP_UP_ANIMATION,1)
		elif(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
			animation_player.play(RUNNING_ANIMATION,1)
		else:
			animation_player.play(IDLE_ANIMATION,1)



func _physics_process(delta: float) -> void:
	if(mode == PlayerMode.ADVENTURE):
		#FORWARD
		var forwardDir = transform.basis.z.normalized()  # Godot's "forward" is -Z
		var forward_movement = movement.z #We go forward
		linear_velocity.x = forwardDir.x * (forward_movement * FORWARD_SPEED * delta)
		linear_velocity.z = forwardDir.z * (forward_movement * FORWARD_SPEED * delta)
	else:
		linear_velocity = Vector3.ZERO



#var target_cam_start_position:Vector2
#var click_start_position:Vector2
#var relative_mouse_coords:Vector2

func _input(event: InputEvent) -> void:
	#TODO: Mouse movements
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#click_start_position = event.position
			#target_cam_start_position = target_cam_offset
	## Check for mouse movement while a drag is likely happening
	#if event is InputEventMouseMotion:
		#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			#relative_mouse_coords = event.position - click_start_position
			#print("Relative Drag Coordinates: ", relative_mouse_coords)
			#target_cam_offset.x = (relative_mouse_coords.y/1000) - target_cam_start_position.y
			#target_cam_offset.y = (relative_mouse_coords.x/1000) - target_cam_start_position.x
	if event is InputEventKey:
		if(mode == PlayerMode.ADVENTURE):
			if Input.is_action_just_pressed("Forward"):
				movement.z = 1;
			elif Input.is_action_just_released("Forward"):
				movement.z = 0;
				
			if Input.is_action_just_pressed("Backward"):
				movement.z = -1;
				targetRotation = rotation.y+PI;
			elif Input.is_action_just_released("Backward"):
				movement.z = 0;
				
			if Input.is_action_just_pressed("Left"):
				movement.x = 1;
				if(movement.z == 0):
					targetRotation = rotation.y+PI/2
			elif Input.is_action_just_released("Left"):
				movement.x = 0;
				target_cam_offset.y = rotation.y
				
			if Input.is_action_just_pressed("Right"):
				movement.x = -1;
				if(movement.z == 0):
					targetRotation = rotation.y-PI/2
			elif Input.is_action_just_released("Right"):
				movement.x = 0;
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
