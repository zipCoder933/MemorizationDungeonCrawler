extends RigidBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"
const DEATH_ANIMATION = "death Retarget"




enum PlayerMode{
	ADVENTURE,
	FACTS,
	GAME_OVER
}
#camera
@export var phantom_camera_3d: PhantomCamera3D
var camRotation = Vector3(0, 0, 0)
const cameraSensitivity:float = 2;
var cam_offset:Vector2 = Vector2(0,0)
var target_cam_offset:Vector2 = Vector2(0,0)
#movement
var movement:Vector3 = Vector3.ZERO
var is_on_floor:bool = false
const FORWARD_SPEED = 300
const TURN_SPEED = 15;
const PLAYER_STEER_MOUSE:bool = false
var targetRotation:float;
var mode = PlayerMode.ADVENTURE

#health
signal health_changed
const MAX_HEALTH = 1
var health:float = 1

func change_health(amt):
	health = health + amt
	if(health > MAX_HEALTH):
		health = MAX_HEALTH
	if(health < 0):
		gameOver()
	health_changed.emit(health)
	
func gameOver():
	Globals.game_over.emit()
	mode = PlayerMode.GAME_OVER
	animation_player.play(DEATH_ANIMATION,1)

func _ready():
	print("PHANTOM CAMERA ",phantom_camera_3d)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.adventure_mode.connect(_global_adventure_mode)

var target:WorldFlashCard = null

func _global_fact_answering_mode(target2:WorldFlashCard):#target:Vector3
	target = target2
	print("Fact mode ",target)
	mode = PlayerMode.FACTS

func _global_adventure_mode():
	print("Adventure mode")
	mode = PlayerMode.ADVENTURE

func _process(delta:float):
	if(mode == PlayerMode.GAME_OVER):
		linear_velocity = Vector3.ZERO
		animation_player.play(DEATH_ANIMATION,1)
	else:
		#update camera pan/tilt around the player
		var screen_size = get_viewport().get_visible_rect().size
		#var mouse_pos = -((get_viewport().get_mouse_position() / screen_size) * 2.0 - Vector2(1, 1))
		var forwardDir = transform.basis.z.normalized();
		
		if Input.is_action_pressed("Camera Left"):
			cam_offset.y += 0.05
			target_cam_offset.y = cam_offset.y
		elif Input.is_action_pressed("Camera Right"):
			cam_offset.y -= 0.05
			target_cam_offset.y = cam_offset.y
		elif(abs(movement.x) == 0): 	#Are we moving left or right?
			cam_offset.y = lerp(cam_offset.y, target_cam_offset.y, cameraSensitivity*delta)
	
	#The camera orientation influences the player
		camRotation.y = PI + cam_offset.y;
		camRotation.x = -0.349 + cam_offset.x;# + (normalized_pos.y * cameraSensitivity)
		phantom_camera_3d.set_third_person_rotation(camRotation)
		#Animations
		if( linear_velocity.y > 0.5 ):
			animation_player.play(JUMP_UP_ANIMATION,1)
		elif(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
			animation_player.play(RUNNING_ANIMATION,1)
		else:
			animation_player.play(IDLE_ANIMATION,1)




func _physics_process(delta: float) -> void:
	#For top down third person movement
	#if(mode == PlayerMode.ADVENTURE):
	var forwardDir = transform.basis.z.normalized()  # Godot's "forward" is -Z
	
	var steering = (movement.x * PI/2)
	
	#Are we going backwards?
	if(movement.z < 0):
		targetRotation = phantom_camera_3d.get_third_person_rotation().y + steering
	else: #Are we going forwards?
		targetRotation = phantom_camera_3d.get_third_person_rotation().y + PI + steering
	rotation.y = lerp_angle(rotation.y , targetRotation, delta * TURN_SPEED)
	
	
	var forward_movement = max(abs(movement.x), abs(movement.z))
	linear_velocity.x = forwardDir.x * (forward_movement * FORWARD_SPEED * delta)
	linear_velocity.z = forwardDir.z * (forward_movement * FORWARD_SPEED * delta)
		
	#elif(mode == PlayerMode.FACTS):
		#linear_velocity = Vector3.ZERO
		#var dir = (target.position - position).normalized()
		#rotation.y = atan2(dir.x, dir.z) + PI
		#if( linear_velocity.y > 0.5 ):
			#animation_player.play(JUMP_UP_ANIMATION,1)
		#elif(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
			#animation_player.play(RUNNING_ANIMATION,1)
		#else:
			#animation_player.play(IDLE_ANIMATION,1)
	#elif(mode == PlayerMode.GAME_OVER):
		#linear_velocity = Vector3.ZERO
		#animation_player.play(DEATH_ANIMATION,1)

func _input(event: InputEvent) -> void:
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
