extends Node3D

const DOOR = preload("uid://bdnosseu7fsm")
const FLOOR = preload("uid://bvoe5plbouam2")
const WALL = preload("uid://bpunwt6bwc3bm")


"""
The level data
Vector2 -> node list
"""
var data: Dictionary = {}
const WALL_LENGTH =  Wall.WALL_SIZE
const WALL_THICKNESS =  Wall.WALL_THICKNESS
const HALF_WALL_LENGTH =  Wall.WALL_SIZE / 2

#Private
func add_entry(key: Vector3, value: Node) -> void: #Add a node to the array for this Vector2 key
	key = _format_vec3(key)
	value.position = key
	add_child(value)
	
	data[key] = data.get(key, [])
	data[key].append(value)

func get_entry(key: Vector3) -> Array: #Return the array stored at the key (or an empty one if none)
	key = _format_vec3(key)
	return data.get(key, [])

func remove_entries(key: Vector3) -> void:
	for node in get_entry(key): #delete nodes
		node.queue_free()
	data.erase(_format_vec3(key))
	
func clear_entries() -> void:# Remove everything
	for node in data.values():#delete nodes
		node.queue_free()
	data.clear()

func _format_vec3(vec:Vector3) -> Vector3:
	return Vector3(vec.x * WALL_LENGTH, vec.y, vec.z * WALL_LENGTH)

"""
Procedural generation of dungeons:
		Spawn a random enemy, door or chest along the path
	
1. Generate a path from the start position to some ending
2. Generate branches going outward
3. Make a large room on the branches
4. Spawn enemies in the branches 
"""




func wall(x:float, z:float, res:Resource, dir:Direction) -> Node3D:
	print("Resource: ",res)
	var instance = res.instantiate()
	if(dir == Direction.ZPOS):
		instance.rotation.y = PI/2
	elif(dir == Direction.ZNEG):
		instance.rotation.y = -(PI/2)
	elif(dir == Direction.XPOS):
		instance.rotation.y = PI
	add_entry(Vector3(x,0,z), instance)
	return instance

func box(x:int, z:int, keepX:bool, keepZ:bool, addDoors:bool):
	if searched.has(Vector3i(x,0,z)):
		wall(x, z + 0.5, DOOR, Direction.XPOS)
		wall(x + 1, z + 0.5, DOOR, Direction.XNEG)
		wall(x + 0.5, z, DOOR, Direction.ZPOS)
		wall(x + 0.5, z + 1, DOOR, Direction.ZNEG)
		
	_place_wall(x, z + 0.5, Direction.XPOS, keepX,addDoors)
	_place_wall(x + 1, z + 0.5, Direction.XNEG, keepX,addDoors)
	_place_wall(x + 0.5, z, Direction.ZPOS, keepZ,addDoors)
	_place_wall(x + 0.5, z + 1, Direction.ZNEG, keepZ,addDoors)
	
	searched[Vector3i(x,0,z)] = true #ADD NEW ENRTY

func is_area_clear(x: int, z: int, radius: int) -> bool:
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var pos = Vector3i(x + dx, 0, z + dz)
			if searched.has(pos):
				return false
	return true


func arena(x: int, z: int, x_radius: int, z_radius: int, direction: Direction, testMode:bool) -> bool:
	var final = moveIn(Vector3(x,0,z),direction)
	x = final.x;
	z = final.z;
	
	if direction == Direction.ZPOS:
		for ox in range(x-z_radius,x+z_radius+1):#Spread out
			for oz in range(z,z+(x_radius * 2)+1):#forward
				var coord = Vector3(ox,0,oz)
				if testMode:
					if(searched.has(coord)):
						return false
				else:
					box(ox,oz,false,false, false)
		if !testMode:
			wall(x + 0.5, z, DOOR, direction)
	elif direction == Direction.ZNEG:
		for ox in range(x-z_radius,x+z_radius+1):#Spread out
			for oz in range(z-(x_radius * 2), z+1):#forward
				var coord = Vector3(ox,0,oz)
				if testMode:
					if(searched.has(coord)):
						return false
				else:
					box(ox,oz,false,false, false)
		if !testMode:
			wall(x + 0.5, z + 1, DOOR, direction)
	elif direction == Direction.XNEG:
		for oz in range(z-z_radius,z+z_radius+1):#Spread out
			for ox in range(x-(x_radius * 2), x+1):#forward
				var coord = Vector3(ox,0,oz)
				if testMode:
					if(searched.has(coord)):
						return false
				else:
					box(ox,oz,false,false, false)
		if !testMode:
			wall(x + 1, z + 0.5,DOOR, direction)
	else:
		for oz in range(z-z_radius,z+z_radius+1):#Spread out
			for ox in range(x,x+(x_radius * 2)+1):#forward
				var coord = Vector3(ox,0,oz)
				if testMode:
					if(searched.has(coord)):
						return false
				else:
					box(ox,oz,false,false, false)
		if !testMode:
			wall(x, z + 0.5, DOOR,direction)
	return true

func _place_wall(x: float, z: float, dir:Direction, keepExistingWalls: bool=true, addDoors:bool = false) -> void:
	var coords = Vector3(x, 0, z)
	var entry = get_entry(coords)
	if entry.size() > 0:
		if(!keepExistingWalls):
			remove_entries(coords)
			if(addDoors):
				wall(x, z, DOOR,dir)
	else:
		wall(x, z, WALL,dir)

enum Direction {XPOS,XNEG,ZPOS,ZNEG}



func moveIn(place:Vector3, direction:Direction) -> Vector3:
	if direction == Direction.XPOS:
		place.x +=1
	elif direction == Direction.ZPOS:
		place.z +=1
	elif direction == Direction.XNEG:
		place.x -= 1
	else:
		place.z -=1
	return place

var count = 0

func _process(delta):
	count+=1
	#if(count > 50):
		#count = 0
		#place = searched.keys()[randi_range(0,searched.keys().size()-1)]
		#var direction =Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()  # to the right
		#var length = randi_range(5,50)
		#var end_pls:Vector3 = (Vector3(place) + direction * length)
		#if is_area_clear(end_pls.x, end_pls.z, 6):
			#var steps = path(place, end_pls, 25,0,arenaSize)


var counter:int = 0
var searched: Dictionary = {}
var place  = Vector3(0,0,0)

func findDirectionThatPointsToTarget(end:Vector3) -> Direction:
	#Find the direction that takes us closer to the goal
	var distances = {
		Direction.XPOS: moveIn(place, Direction.XPOS).distance_to(end),
		Direction.XNEG: moveIn(place, Direction.XNEG).distance_to(end),
		Direction.ZPOS: moveIn(place, Direction.ZPOS).distance_to(end),
		Direction.ZNEG: moveIn(place, Direction.ZNEG).distance_to(end)
	}

	# Find the direction with the lowest distance
	var best_dir = null
	var best_dist = INF

	for dir in distances.keys():
		if distances[dir] < best_dist:
			best_dist = distances[dir]
			best_dir = dir
	return best_dir

class PathStep:
	func _init(path2, door2):
		path_pos = path2;
		placeDoor = door2
	
	var path_pos:Vector3i;
	var placeDoor:bool;

func alreadyPathHere(path_steps:Array[PathStep],target_pos:Vector3i) -> bool:
	if searched.has(Vector3i(target_pos)):
		return true
	for step in path_steps:
		if step.path_pos == target_pos:
			return true
	return false

func pathDirection(direction:Direction, length:int, placeDoors:bool, idea_path) -> bool:
	var madeBox = false
	for j in range(length):
		var tPlace = moveIn(place,direction)#Move temporarily
		var tPlace2 = moveIn(tPlace,direction)#Move again
		var goingX = (direction == Direction.XPOS or direction == Direction.XNEG)
		
		if alreadyPathHere(idea_path,Vector3i(tPlace)) or\
			alreadyPathHere(idea_path,Vector3i(tPlace2)):
			break
		elif goingX and\
		  (alreadyPathHere(idea_path,Vector3i(tPlace.x,tPlace.y,tPlace.z+1)) or\
		  alreadyPathHere(idea_path,Vector3i(tPlace.x,tPlace.y,tPlace.z-1))):
			break
		elif !goingX and\
		 (alreadyPathHere(idea_path,Vector3i(tPlace.x+1,tPlace.y,tPlace.z)) or\
		  alreadyPathHere(idea_path,Vector3i(tPlace.x-1,tPlace.y,tPlace.z))):
			break
		else: #Place the box
			place = tPlace
			madeBox=true
			if(j > 0): #We will never need a door mid-path
				placeDoors = false
			idea_path.append(PathStep.new(Vector3i(place),placeDoors))
	return madeBox

func path(path_start:Vector3, path_end:Vector3, max_failures:int, arenaSize:int, failedLevelSurvival:float) -> int:
	place = path_start
	var stepsTaken = 0
	var failures = 0
	var lastSuccesfullDirection = Direction.XPOS
	var lastDirection = Direction.XPOS
	var idea_path:Array[PathStep]

	for i in range(0, 100000):
		var direction = findDirectionThatPointsToTarget(path_end)
		if failures > 0:
			direction = Direction[Direction.keys()[randi_range(0,3)]]#random
			
		lastDirection = direction
			
		var placeDoors = true #Always place a door at the beginning of a path
		if(stepsTaken > 0):
			placeDoors = randf() > 0.5
		if(place.is_equal_approx(path_end)):
			break;
		if pathDirection(direction,randi_range(1,4),placeDoors,idea_path):
			lastSuccesfullDirection = direction
			stepsTaken +=1
			failures = 0
		else:
			failures += 1
		if(failures > max_failures):
			print("Branch failed!")
			break
		elif(place.distance_to(path_end) < CLOSENESS_TO_END_PATH_END):
			break
	
	#Actually put downt the boxes
	if(failures < max_failures or randf() < failedLevelSurvival):
		for step in idea_path:
			box(step.path_pos.x,step.path_pos.z,false,false,step.placeDoor)
		
		#Only place the arena if we didnt fail
		if(stepsTaken > 0 and failures < max_failures and arena(place.x,place.z, arenaSize,arenaSize, lastSuccesfullDirection, true)):
			arena(place.x,place.z, arenaSize,arenaSize, lastSuccesfullDirection, false)
	
	return stepsTaken


const arenaSize = 2;
const CLOSENESS_TO_END_PATH_END = 6;
const start_pos = Vector3(0,0,0)
const main_path_end = Vector3(20,0,20)

func _ready():
	box(start_pos.x, start_pos.z, true, true, false)
	#arena(start_pos.x-2,start_pos.z, 1,1, Direction.XPOS, false)
	print("MAIN: ", path(start_pos, main_path_end,25,arenaSize+2, 1))
	
	for i in range(0,100):
		place = searched.keys()[randi_range(0,searched.keys().size()-1)]
		var direction =Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()  # to the right
		var length = randi_range(5,50)
		var end_pls:Vector3 = (Vector3(place) + direction * length)
		if is_area_clear(end_pls.x, end_pls.z, (arenaSize) + CLOSENESS_TO_END_PATH_END + 2):
			var steps = path(place, end_pls, 25, arenaSize, 0.2)

	_place_floors(searched, 250)




























#FLOORS =========================================================
func _place_floors(floor_map: Dictionary, floor_size: int = 500) -> void:
	if floor_map.is_empty():
		return
	
	# Find the min and max bounds of all true entries
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for key in floor_map.keys():
		var coords2 = _format_vec3(key)
		if not floor_map[key]:
			continue
		min_x = min(min_x, coords2.x)
		max_x = max(max_x, coords2.x)
		min_z = min(min_z, coords2.z)
		max_z = max(max_z, coords2.z)
	
	# Now iterate the bounding area in steps of floor_size (cell units × floor_size)
	for x in range(min_x, max_x + 1 + floor_size, floor_size):
		for z in range(min_z, max_z + 1 + floor_size, floor_size):
				var instance = FLOOR.instantiate()
				instance.position.x = x;
				instance.position.z = z
				add_child(instance)
