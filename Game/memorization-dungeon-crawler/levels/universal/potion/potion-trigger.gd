extends StaticBody3D
class_name PotionTrigger
@onready var potion: RigidBody3D = $".."


func delete_potion():
	potion.queue_free()
