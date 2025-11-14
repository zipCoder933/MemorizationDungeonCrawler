extends Node3D

@onready var cam := get_viewport().get_camera_3d()
@export var render_distance = 10

func _process(delta):
	if cam:
		var dist := global_position.distance_to(cam.global_position)
		if dist > render_distance:
			visible = false    # *poof*
		else:
			visible = true     # *un-poof*
