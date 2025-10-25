extends StaticBody3D
class_name DoorTrigger

const Flashcard = preload("uid://dpwndab3fxwor")

@onready var door: Node3D = $"../door mesh"
var card;

var door_open:float = 3
var door_closed:float = 0
var open:bool = false
const slide_speed = 1;

func _ready():
	for child in get_children():
		if child.is_in_group("3dCard"):
			card =  child
	print("Flashcard: ",card)

func open_door(open2:bool):
	var questions = [ 
		Question.new(false, "5+5", "10", 5),
		Question.new(false, "10+10", "20", 5),
		Question.new(false, "15+15", "30", 5),
		Question.new(false, "20+20", "40", 5)
	 ]
	card.drill(questions)
	#open = open2;

func _process(delta):
	if open and door.position.y < door_open:
		door.position.y = door.position.y + (slide_speed*delta)
	elif !open and door.position.y > door_closed:
		door.position.y = door.position.y - (slide_speed*delta)
