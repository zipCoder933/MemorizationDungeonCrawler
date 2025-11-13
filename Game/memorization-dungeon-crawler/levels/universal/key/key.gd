extends Node3D
class_name KeyNode

const animation_speed = 15
const float_position:float = 1

func _ready():
	position.y=0

func _process(delta:float):
	if(position.y < float_position - 0.01):
		rotate_y(delta * 8)
		position.y = lerp(position.y, float_position, delta * animation_speed)
	else:
		rotate_y(delta * 2)
		position.y = float_position + (sin(delta * 10 )*0.5)
