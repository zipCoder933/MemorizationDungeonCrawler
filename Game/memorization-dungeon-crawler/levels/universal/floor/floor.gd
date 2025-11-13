extends StaticBody3D
class_name FloorCeiling

@onready var floor: MeshInstance3D = %floor
@onready var ceiling: MeshInstance3D = %ceiling

static var ceiling_material:StandardMaterial3D
static var floor_material:StandardMaterial3D

func _ready():
	if( floor_material !=null):
		floor.set_surface_override_material(0, floor_material)
	
	if (ceiling_material !=null):
		ceiling.set_surface_override_material(0, ceiling_material)
