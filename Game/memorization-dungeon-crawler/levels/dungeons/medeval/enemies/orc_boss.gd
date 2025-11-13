extends Node3D

@onready var _3d_flashcard: WorldFlashCard = %"3dFlashcard"
@onready var trigger: GoblinTrigger = %trigger
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D

func _ready():
	_3d_flashcard.signal_flashcard_finished_drill.connect(_finished_drill)

#Disable the orc boss until we have completed all bosses
func _process(delta: float) -> void:
	collision_shape_3d.disabled = Globals.get_player().keys < Globals.totalArenas
	
func _finished_drill(success, all):
		if(success > 0):
			Globals.victory_event()
