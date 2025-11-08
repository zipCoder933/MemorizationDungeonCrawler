extends StaticBody3D
class_name DoorTrigger
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")

@export var door:Door;
@onready var _3d_flashcard: Sprite3D = $"3dFlashcard"

func _ready():
	_3d_flashcard.signal_flashcard_finished_drill.connect(_on_d_flashcard_finished_drill)

func open_door(open2:bool):
	if(!door.open):
		Globals.drill_flashcards([ 
			CardsHandler.randomCardInCurrentLevel().toQuestion(1,SaveHandler.currentLevel)
		 ], _3d_flashcard)

func _on_d_flashcard_finished_drill(succeeded:int, questions:int) -> void:
	if(succeeded >= questions):
		door.setOpen(true)
