extends StaticBody3D
class_name KeyTrigger
@onready var key: KeyNode = $".."

func delete_key():
	key.queue_free()
