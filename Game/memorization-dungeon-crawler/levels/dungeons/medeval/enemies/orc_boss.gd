extends Node3D

@onready var _3d_flashcard: WorldFlashCard = %"3dFlashcard"
@onready var trigger: GoblinTrigger = %trigger
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var boss: Node3D = $"../.."

func _ready():
	pass
	
#Disable the orc boss until we have completed all bosses
func _process(delta: float) -> void:
	if(Globals.get_player().keys < Globals.totalArenas):
		boss.visible=false #TODO: Add a elevator animation when we spawn the boss
		collision_shape_3d.disabled = true
	else:
		boss.visible=true
		collision_shape_3d.disabled=false
