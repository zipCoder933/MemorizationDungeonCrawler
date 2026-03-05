extends Node3D
class_name KeyNode

const animation_speed = 10
const float_position:float = 1
var is_boss_key = false

func _ready():
	position.y=0

func _process(delta:float):
	if(position.y < float_position - 0.01):
		rotate_y(delta * 16)
		position.y = lerp(position.y, float_position, delta * animation_speed)
	else:
		rotate_y(delta * 4)
		position.y = float_position
