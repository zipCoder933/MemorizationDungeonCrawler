extends StaticBody3D
class_name DoorTrigger
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

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
			CardsHandler.randomCardInCurrentLevel().toQuestion(1,LevelsHandler.current_level)
		 ])

func _on_d_flashcard_finished_drill(succeeded:int, questions:int) -> void:
	print("succeeded=",succeeded," questions=", questions)
	if(succeeded >= questions):
		door.setOpen(true)

func _on_d_flashcard_single_drill(success:bool) -> void:
	pass
