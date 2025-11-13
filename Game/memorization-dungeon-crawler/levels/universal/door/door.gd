extends StaticBody3D
class_name Door
var open:bool = false

@export var door_open_y:float = 3
var door_closed_y:float
@export var slide_speed = 1;
@export var door:Node

func _ready():
	door_closed_y = door.position.y

func setOpen(open2:bool):
	open = open2;

func _process(delta):
	if(door_open_y > door_closed_y):
		if open and door.position.y < door_open_y:
			door.position.y = door.position.y + (slide_speed*delta)
		elif !open and door.position.y > door_closed_y:
			door.position.y = door.position.y - (slide_speed*delta)
	else:
		if open and door.position.y > door_open_y:
			door.position.y = door.position.y - (slide_speed*delta)
		elif !open and door.position.y < door_closed_y:
			door.position.y = door.position.y + (slide_speed*delta)
