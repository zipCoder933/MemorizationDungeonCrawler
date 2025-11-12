extends StaticBody3D
class_name Door
var open:bool = false

@export var door_open_y:float = 3
@export var door_closed_y:float = 0
@export var slide_speed = 1;
@export var door:Node

func setOpen(open2:bool):
	open = open2;

func _process(delta):
	if open and door.position.y < door_open_y:
		door.position.y = door.position.y + (slide_speed*delta)
	elif !open and door.position.y > door_closed_y:
		door.position.y = door.position.y - (slide_speed*delta)
