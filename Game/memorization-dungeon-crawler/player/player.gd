extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

#func _input(event: InputEvent) -> void:
	#if Input.is_action_just_pressed("Forward"):
		#movement.z = 1;
	#elif Input.is_action_just_released("Forward"):
		#movement.z = 0;
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Forward"):
		animation_player.play("jump up Retarget",1)
