extends StaticBody3D
class_name DoorTrigger

@export var door:Door;
@onready var _3d_flashcard: Sprite3D = $"3dFlashcard"

func _ready():
	_3d_flashcard.finished_drill.connect(_on_d_flashcard_finished_drill)
	_3d_flashcard.single_drill.connect(_on_d_flashcard_finished_drill)
	#for child in get_children():
		#if child.is_in_group("3dCard"):
			#card =  child
	#print("Flashcard: ",card)

func open_door(open2:bool):
	if(!door.open):
		_3d_flashcard.drill([ 
		Question.new(false, "5+5", "10", 5),
		Question.new(false, "10+10", "20", 5),
		Question.new(false, "15+15", "30", 5),
		Question.new(false, "20+20", "40", 5)
		 ])

func _on_d_flashcard_finished_drill(succeeded:int) -> void:
	#print("A ",succeeded)
	if(succeeded > 2):
		door.setOpen(true)

func _on_d_flashcard_single_drill(success:bool) -> void:
	pass
