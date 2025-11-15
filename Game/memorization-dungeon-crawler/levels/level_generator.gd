extends Node3D




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

func get_arena_center(x: int, z: int, x_radius: int, z_radius: int, direction: Direction) -> Vector3:
	var cx = float(x)
	var cz = float(z)
	match direction:
		Direction.ZPOS:
			cz += 0.0 + x_radius      # move 1 forward for door gap, then half arena depth
		Direction.ZNEG:
			cz -= 0.0 + x_radius
		Direction.XPOS:
			cx += 0.0 + x_radius
		Direction.XNEG:
			cx -= 0.0 + x_radius
	# Shift by +0.5 to center in the tile grid
	return Vector3(cx + 0.5, 0, cz + 0.5)




func arena(x: int, z: int, x_radius: int, z_radius: int, direction: Direction, testMode:bool, enemy:Resource) -> bool:
	var final = moveIn(Vector3(x,0,z),direction)
	x = final.x;
	z = final.z;
	
	if !testMode and enemy !=null:
		var instance = enemy.instantiate()
		var enemyPos = get_arena_center(x,z,x_radius,z_radius,direction)
		instance.position = _format_vec3(enemyPos)
		add_child(instance)
	
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

#func _process(delta):
	#count+=1
	##if(count > 50):
		##count = 0
		##place = searched.keys()[randi_range(0,searched.keys().size()-1)]
		##var direction =Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()  # to the right
		##var length = randi_range(5,50)
		##var end_pls:Vector3 = (Vector3(place) + direction * length)
		##if is_area_clear(end_pls.x, end_pls.z, 6):
			##var steps = path(place, end_pls, 25,0,arenaSize)


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

func path_direction(direction:Direction, length:int, placeDoors:bool, idea_path) -> bool:
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


func path(path_start:Vector3, path_end:Vector3, max_failures:int, \
		starting_arena_size:int, arenaSize:int, failedLevelSurvival:float, boss:bool,\
		set_player_spawn_at_start:bool=false) -> int:
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
			placeDoors = randf() < DOOR_LIKELYHOOD
		#if Engine.is_embedded_in_editor(): #Dont want to worry about doors in editor
				#placeDoors = false
		if(place.is_equal_approx(path_end)):
			break;
		if path_direction(direction,randi_range(1,4),placeDoors,idea_path):
			if(stepsTaken == 0 and starting_arena_size > 0):
				if direction == Direction.XPOS:
					arena(path_start.x+1,path_start.z, starting_arena_size,starting_arena_size, Direction.XNEG, false,null)
					if(set_player_spawn_at_start):
						PLAYER_SPAWN = _format_vec3(\
						get_arena_center(path_start.x+1,path_start.z, starting_arena_size,starting_arena_size, Direction.XNEG))
				elif direction == Direction.XNEG:
					arena(path_start.x-1,path_start.z, starting_arena_size,starting_arena_size, Direction.XPOS, false,null)
					if(set_player_spawn_at_start):
						PLAYER_SPAWN = _format_vec3(\
						get_arena_center(path_start.x-1,path_start.z, starting_arena_size,starting_arena_size, Direction.XPOS))
				elif direction == Direction.ZPOS:
					arena(path_start.x,path_start.z+1, starting_arena_size,starting_arena_size, Direction.ZNEG, false,null)
					if(set_player_spawn_at_start):
						PLAYER_SPAWN = _format_vec3(\
						get_arena_center(path_start.x,path_start.z+1, starting_arena_size,starting_arena_size, Direction.ZNEG))
				else:
					arena(path_start.x,path_start.z-1, starting_arena_size,starting_arena_size, Direction.ZPOS, false,null)
					if(set_player_spawn_at_start):
						PLAYER_SPAWN = _format_vec3(\
						get_arena_center(path_start.x,path_start.z-1, starting_arena_size,starting_arena_size, Direction.ZPOS))
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
		if(stepsTaken > 0 and failures < max_failures and arena(place.x,place.z, arenaSize,arenaSize, lastSuccesfullDirection, true, null)):
			if(boss):
				arena(place.x,place.z, arenaSize,arenaSize, lastSuccesfullDirection, false, ARENA_BOSS)
			else:
				arena(place.x,place.z, arenaSize,arenaSize, lastSuccesfullDirection, false, AREA_ENEMY)
				Globals.totalArenas += 1
	
	return stepsTaken

func load_tex(base: String) -> Texture2D:
	var tex = load(base + ".jpg")
	return tex if tex else load(base + ".png")

func _material(prefix: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = load_tex(prefix + "/texture")
	mat.normal_texture = load_tex(prefix + "/normal")
	mat.texture_repeat = true
	mat.uv1_scale = Vector3(40, 40, 1)
	return mat

var PLAYER_SPAWN:Vector3
#Nodes
var DOOR;
var FLOOR
var WALL;
var AREA_ENEMY;
var ARENA_BOSS;

const arenaSize = 1;
const CLOSENESS_TO_END_PATH_END = 6;
const FAILED_LEVEL_SURVIVAL = 0.3
const DOOR_LIKELYHOOD = 0.3
const DRILLS_TO_ARENA = 15 #How many total drills * card_review_number makes 1 arena in the map?

func _ready():
	DOOR = preload("uid://bdnosseu7fsm")
	AREA_ENEMY = preload("uid://bqoufhp54uwue")
	ARENA_BOSS = preload("uid://bobtcptejmn2a")
	FLOOR = preload("uid://bvoe5plbouam2")
	var floor_size=250

	print("Generating level...")
	var level = SaveHandler.currentLevel
	var game = SaveHandler.currentGame
	var arenas_average = 5
	var includeBossfight = false
	if( level !=null):
		var rd = Globals.random_deterministic(game.seed,game.completed_level)
		#Set the theme
		if(level.theme == Level.LevelTheme.MACHINE):
			DOOR = preload("uid://bv0qtxxmmlnu")
			WALL = preload("uid://c16k18ck0f1hj")
		elif(level.theme == Level.LevelTheme.LAVA):
			DOOR = preload("uid://djjr0ga5jbjrl")
			WALL = preload("uid://bnnvdgktdrjn")
			FLOOR = preload("uid://bawlwsttbkodd")
		elif(level.theme == Level.LevelTheme.ANTARCTIC):
			DOOR = preload("uid://dg4pafqkenvdm")
			WALL = preload("uid://7rxa50lxqn7q")
			FLOOR = preload("uid://ctkt8jvhjfhif")
		elif(level.theme == Level.LevelTheme.JUNGLE):
			floor_size=100
			FLOOR = preload("uid://b61v8qf2ipthl")
			DOOR = preload("uid://lfo3xvyqph2")
			WALL = preload("uid://bul1mahgmqnrl")
			FloorCeiling.ceiling_material = _material("res://assets/dungeons/medeval/variants/ceiling/3")
			FloorCeiling.floor_material = _material("res://assets/dungeons/medeval/variants/floor/4")
		elif(level.theme == Level.LevelTheme.DUNGEON):
			var ceiling_prefix = "res://assets/dungeons/medeval/variants/ceiling/"
			var floor_prefix = "res://assets/dungeons/medeval/variants/floor/"
			var door_choices = [
				preload("uid://bdnosseu7fsm"),
				preload("uid://cybqn7iu5i8eg"),
				preload("uid://diy6r0cvqqg7"),
				preload("uid://dcpufpqme3c85"),
				preload("uid://dfi5w6y8hlkr0"),
				preload("uid://dleju5c66cvvu"),
				preload("uid://djjvv1sa3ysk6"),
				preload("uid://4s0h623tfp4i")
			]
			var wall_choices = [
				preload("uid://bpunwt6bwc3bm"),
				preload("uid://0j4let3yj7fs"),
				preload("uid://bhsk3kl4m1dfo"),
				preload("uid://dqdax1p7cvkte"),
				preload("uid://kyolc7snufaa"),
				preload("uid://bcy3nul1q0sft"),
				preload("uid://cd36i2ec1bcsg"),
				preload("uid://ctgkom7yoctco")
				
			]
			
			if(level.levelType == Level.LevelType.BOSS):
				includeBossfight = true
			
			var cdirs = DirAccess.open(ceiling_prefix).get_directories()
			var fdirs = DirAccess.open(floor_prefix).get_directories()
			var ceiling_choice = rd.randi_range(0, cdirs.size()-1) #Random ceiling
			var floor_choice = rd.randi_range(0, fdirs.size()-1)#Random floor
			var wall_choice = rd.randi_range(0,wall_choices.size()-1) #random wall
			if(game.completed_level==0):
				wall_choice=0
				ceiling_choice=0
				floor_choice=0
			WALL = wall_choices[wall_choice]
			DOOR = door_choices[wall_choice]
			FloorCeiling.ceiling_material = _material(ceiling_prefix + cdirs[ceiling_choice])
			FloorCeiling.floor_material = _material(floor_prefix + fdirs[floor_choice])

		#Calculate how many arenas we want
		var cards = CardsHandler.card_count(level.card_tags)
		var total_drills = level.card_review_number * cards
		print("Total drills: ",total_drills)
		arenas_average = total_drills / DRILLS_TO_ARENA
		print("Arena average: ",arenas_average)
	
	
	var min_path_length = 3
	var max_path_length = 15
	var start_pos = Vector3(0,0,0)
	
	var main_path_dir = Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
	var main_path_length = randi_range(10,20)
	var main_path_end =(Vector3(start_pos) + main_path_dir * main_path_length)
	var number_arenas = clamp(randi_range(arenas_average-3,arenas_average+3), 4, 25)
	Globals.totalArenas = 0
	
	if(includeBossfight):
		#Less arenas in bossfights
		number_arenas = clamp(number_arenas, 3, 8)
		print("BOSS PATH: ",\
		 path(start_pos, main_path_end, 25, 2, arenaSize+2, 1, true, true))
	else:
		print("STANDARD PATH: ",\
		 path(start_pos, main_path_end, 25, 2, arenaSize, 1, false, true))
	
	#arena(start_pos.x-2,start_pos.z, 1,1, Direction.XPOS, false,null)
	print("Center: ",PLAYER_SPAWN)
	Globals.get_player().global_position.x = PLAYER_SPAWN.x
	Globals.get_player().global_position.z = PLAYER_SPAWN.z
	
	for i in range(0,200):
		place = searched.keys()[randi_range(0,searched.keys().size()-1)]
		var direction = Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()  # to the right
		var length = randi_range(min_path_length,max_path_length)
		var end_pls:Vector3 = (Vector3(place) + direction * length)
		if is_area_clear(end_pls.x, end_pls.z, (arenaSize) + CLOSENESS_TO_END_PATH_END + 2):
			var steps = path(place, end_pls, 5, 0, arenaSize, FAILED_LEVEL_SURVIVAL, false)
		if(Globals.totalArenas >= number_arenas):
			break
	
	_place_floors(searched, floor_size)




























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
