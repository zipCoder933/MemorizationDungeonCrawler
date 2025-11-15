extends Node3D

@onready var _3d_flashcard: WorldFlashCard = %"3dFlashcard"
@onready var trigger: GoblinTrigger = %trigger
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var boss_model: Node3D = %BossModel

func _ready():
	pass
	
#Disable the orc boss until we have completed all enemies
func _process(delta: float) -> void:
	if(Globals.get_player().keys < Globals.totalArenas and !Engine.is_embedded_in_editor()):
		boss_model.visible=false
		collision_shape_3d.disabled = true
	else:
		boss_model.visible=true
		collision_shape_3d.disabled=false
