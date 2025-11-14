extends StaticBody3D
class_name KeyTrigger
@onready var key: KeyNode = $".."

func get_key():
	return key

func delete_key():
	key.queue_free()
