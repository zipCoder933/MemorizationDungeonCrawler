extends RigidBody3D
class_name Player

@onready var animation_player: AnimationPlayer = $Knight2/AnimationPlayer
const RUNNING_ANIMATION = "running Retarget"
const JUMP_UP_ANIMATION = "jump up Retarget"
const IDLE_ANIMATION = "Idle Retarget"

#camera
@export var phantom_camera_3d: PhantomCamera3D
var camRotation = Vector3(0, 0, 0)
var cameraSensitivity:float = 60;
var cameraHorizontalOffset:float = 0
var cameraHorizontalOffsetLerp:float = 0.01

#movement
var movement:Vector3 = Vector3.ZERO
var is_on_floor:bool = false
const FORWARD_SPEED = 300
const TURN_LERP_SPEED = 0.2
const TURN_SPEED = 5;
const PLAYER_STEER_MOUSE:bool = true
var targetRotation:float;

#health
signal health_changed
var health:float = 1

func change_health(amt):
	health = health + amt
	if(health > 1):
		health = 1
	health_changed.emit(health)
	
func _ready():
	print("PHANTOM CAMERA ",phantom_camera_3d)

func _process(delta:float):
	print("PHANTOM CAMERA ",phantom_camera_3d)
	#update camera pan/tilt around the player
	var screen_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var normalized_pos = -((mouse_pos / screen_size) * 2.0 - Vector2(1, 1))
	if(movement.z >= 0):
		cameraHorizontalOffset = lerp_angle(cameraHorizontalOffset, rotation.y, cameraHorizontalOffsetLerp)
	camRotation.y = 180 + rad_to_deg(cameraHorizontalOffset) + (normalized_pos.x * cameraSensitivity)
	camRotation.x = -20 + (normalized_pos.y * cameraSensitivity)
	phantom_camera_3d.set_third_person_rotation_degrees(camRotation)

	
func _physics_process(delta: float) -> void:
	#For top down third person movement
	#linear_velocity.x = movement.x * SPEED * delta;
	#linear_velocity.z = movement.z  * SPEED * delta;
	#targetRotation = atan2(linear_velocity.x, linear_velocity.z)
	#rotation.y = lerp_angle(rotation.y, targetRotation, ROTATION_LERP_SPEED)

	#for immersive third person movement
	
	var forward = transform.basis.z.normalized()  # Godot's "forward" is -Z

	if(movement.z == 0):
		rotation.y = lerp_angle(rotation.y , targetRotation, delta * TURN_SPEED)
		linear_velocity.x = forward.x * (abs(movement.x) * FORWARD_SPEED * delta)
		linear_velocity.z = forward.z * (abs(movement.x) * FORWARD_SPEED * delta)
	else:
		if(PLAYER_STEER_MOUSE):
			var steering = (movement.x * movement.z * PI/2)
			if(movement.z < 0):
				targetRotation = phantom_camera_3d.get_third_person_rotation().y + steering
			else:
				targetRotation = phantom_camera_3d.get_third_person_rotation().y + PI + steering
			rotation.y = lerp_angle(rotation.y , targetRotation, delta * TURN_SPEED)
		else:
			if(movement.z >= 0):
				targetRotation = rotation.y
				rotation.y += movement.x * movement.z * delta * TURN_SPEED
			else:
				rotation.y = lerp_angle(rotation.y , targetRotation, delta * TURN_SPEED)
		linear_velocity.x = forward.x * (abs(movement.z) * FORWARD_SPEED * delta)
		linear_velocity.z = forward.z * (abs(movement.z) * FORWARD_SPEED * delta)


	if( linear_velocity.y > 0.5 ):
		animation_player.play(JUMP_UP_ANIMATION,1)
	elif(abs(linear_velocity.x) > 0 or abs(linear_velocity.z) > 0):
		animation_player.play(RUNNING_ANIMATION,1)
	else:
		animation_player.play(IDLE_ANIMATION,1)
		
		
func _input(event: InputEvent) -> void:
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
		
	if Input.is_action_just_pressed("Right"):
		movement.x = -1;
		if(movement.z == 0):
			targetRotation = rotation.y-PI/2
	elif Input.is_action_just_released("Right"):
		movement.x = 0;
		
	if is_on_floor == true and Input.is_action_just_pressed("Jump"):
		print("Jump")
		animation_player.play(JUMP_UP_ANIMATION,1)
		apply_central_impulse(Vector3(0, 10, 0))
		is_on_floor = false


func _on_body_entered(body: Node) -> void:
	if body is Floor:
		is_on_floor = true
	#elif body is DoorTrigger:
		#print("PLAYER IN DOOR")
		#body.open_door(true)
