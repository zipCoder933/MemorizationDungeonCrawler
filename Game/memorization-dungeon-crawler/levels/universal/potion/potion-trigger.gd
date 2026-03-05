extends StaticBody3D
class_name PotionTrigger
@onready var potion: RigidBody3D = $".."


func _process(delta: float) -> void:
	if(Globals.get_player() != null):
		var player = Globals.get_player()
		if(player.global_position.distance_to(global_position) < 1):
			player.set_health(1)
			delete_potion()

func delete_potion():
	potion.queue_free()
