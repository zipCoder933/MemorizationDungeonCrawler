extends StaticBody3D
class_name DoorTrigger
const CardsHandler = preload("uid://cc0wwewiey4d7")
const LevelsHandler = preload("uid://bte11e0fapqes")
const FLASHCARD_TIME_MULTIPLIER = 0.9 #The doors shouldnt be easy to open

@export var door:Door;
@onready var _3d_flashcard: Sprite3D = $"3dFlashcard"

func _ready():
	_3d_flashcard.signal_flashcard_finished_drill.connect(_on_d_flashcard_finished_drill)

func open_door(open2:bool):
	if(!door.open):
		Globals.drill_flashcards(1, _3d_flashcard, FLASHCARD_TIME_MULTIPLIER)
	
func _on_d_flashcard_finished_drill(results:FlashcardDrillResults) -> void:
	if(results.succeeded > 0):
		door.setOpen(true)
