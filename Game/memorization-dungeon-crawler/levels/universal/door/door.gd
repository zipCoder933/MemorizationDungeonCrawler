extends StaticBody3D
class_name Door
var door_open:float = 3
var door_closed:float = 0
var open:bool = false
const slide_speed = 1;
@onready var door: Node3D = %"door mesh"

func setOpen(open2:bool):
	open = open2;

func _process(delta):
	if open and door.position.y < door_open:
		door.position.y = door.position.y + (slide_speed*delta)
	elif !open and door.position.y > door_closed:
		door.position.y = door.position.y - (slide_speed*delta)
