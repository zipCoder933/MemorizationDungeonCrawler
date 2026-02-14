extends Node

#An array of Levels
static var levels: Array[Level] = []

#start and goal speed in seconds
static var start_speed:float
static var goal_speed:float
static var midgame_start_speed:float
static var midgame_goal_speed:float

static var _last_level_tags:Array[String] = []
#---
static var level_index:int = 0
func _ready():
	pass
	
static func get_level(level_indx:int) -> Level:
	return levels[clamp(level_indx-1, 0, levels.size()-1)]

static func load_from_file(file_path: String, results:GameJsonLoadInfo = GameJsonLoadInfo.new(), verbose:bool = false) -> bool:
	# Reset globals safely
	levels = []
	_last_level_tags = []
	start_speed = 0
	goal_speed = 0
	level_index = 0
	var dungeon_start_speed = 0
	var dungeon_goal_speed = 0
	
	print("Loading levels:", file_path)

	# ---------------------------
	# FILE LOADING
	# ---------------------------
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		results.write("Failed to open JSON file: %s" % file_path)
		return false

	var content := ""
	
	# File read safety
	var read_ok := true
	if FileAccess.get_open_error() != OK:
		read_ok = false
	else:
		content = file.get_as_text()

	file.close()

	if not read_ok:
		results.write("Failed to read JSON file (permissions or corrupted file).")
		return false

	# ---------------------------
	# JSON PARSE
	# ---------------------------
	var result = JSON.parse_string(content)
	if typeof(result) != TYPE_DICTIONARY:
		results.write("JSON root is not an object/dictionary.")
		return false
	
	var json_data:Dictionary = result

	# ---------------------------
	# TOP-LEVEL GAME SPEED PROPS
	# ---------------------------
	start_speed = JsonUtils.get_float(json_data, "starting_answer_speed_sec", 10.0)
	goal_speed  = JsonUtils.get_float(json_data, "goal_answer_speed_sec", 1.0)

	#In the future we could make this configurable
	var progression_curve:float = 0.3
	
	var default_start_speed:float = lerp(start_speed, goal_speed, clampf(JsonUtils.get_float(json_data, "midgame_start_speed_percent", 0.1), 0, 0.9 ))
	var default_goal_speed:float  = lerp(start_speed, goal_speed, clampf(JsonUtils.get_float(json_data, "midgame_goal_speed_percent", 0.82), 0.1 ,1 ))
	midgame_start_speed = default_start_speed
	midgame_goal_speed  = default_goal_speed
	
	if(verbose):
		print("start_speed=",start_speed,"\ngoal_speed=",goal_speed)
		print("midgame_start_speed=",midgame_start_speed,"\nmidgame_goal_speed=",default_goal_speed)
		#print("test ",Globals.smart_lerp(10, 0.4, 0.95))

	

	print("GAME SPEED (SEC): start=%2f; end=%2f; mid-start=%2f; mid-end=%2f;" %
		[start_speed, goal_speed, midgame_start_speed, midgame_goal_speed])

	# ---------------------------
	# LOAD DUNGEONS
	# ---------------------------
	var dungeons = json_data.get("dungeons", [])

	# validate dungeons list
	if typeof(dungeons) != TYPE_ARRAY:
		results.write("'dungeons' must be an array.")
		return false

	var learned_tags:Array[String] = []
	const emptyArray: Array[String] = []

	for dungIndx in dungeons.size():
		var dungeon = dungeons[dungIndx]
		# Dungeon validation
		if typeof(dungeon) != TYPE_DICTIONARY:
			results.write("Dungeon %d is not a dictionary." % dungIndx)
			return false

		if(verbose):
			print("\n--- Dungeon #%d ---" % dungIndx)

		# ---------------------------
		# SPEED 
		# We can get the speed from each dungeon or from the default valeus
		# ---------------------------
		dungeon_start_speed = midgame_start_speed
		if(dungeon.has("start_speed_percent")): 
			var lerp_value =  JsonUtils.get_float(dungeon, "start_speed_percent",0)
			dungeon_start_speed = lerp(start_speed, goal_speed, lerp_value)
		
		dungeon_goal_speed = midgame_goal_speed
		if(dungeon.has("goal_speed_percent")):
			var lerp_value =  JsonUtils.get_float(dungeon, "goal_speed_percent",0)
			dungeon_goal_speed  = lerp(start_speed, goal_speed, lerp_value)
		elif(dungIndx == dungeons.size()-1):
			dungeon_goal_speed = goal_speed
		
		if(verbose):
			print("Dungeon speed: start=",dungeon_start_speed,"; end=",dungeon_goal_speed)

		# ---------------------------
		# DRILL LEVELS
		# ---------------------------
		var levelsjson:Variant = dungeon.get("levels", [])
		
		if typeof(levels) != TYPE_ARRAY:
			results.write("'levels' in dungeon %d must be an array." % dungIndx)
			return false

		var themed_tags:Array[String] = []
		var total_levels_in_dungeon:int = 0
		var total_levels_so_far:int = 0
		
		for level_indx in range(levelsjson.size()):
			var level = levelsjson[level_indx]
			var levelCount = JsonUtils.get_int(level, "count", 0)
			if levelCount > 0:
				total_levels_in_dungeon+=levelCount
		
		
		for level_indx in range(levelsjson.size()):
			var level = levelsjson[level_indx]
			var levelCount = JsonUtils.get_int(level, "count", 0)
			if levelCount <= 0:
				continue
			
			if typeof(level) != TYPE_DICTIONARY:
				results.write("A themed level in dungeon %d is not a dictionary." % dungIndx)
				return false
				
			# Get tags
			var hasNewCards := false
			var raw_tags = JsonUtils.get_string_array(level, "tags",[])
			var level_tags:Array[String] = []
			
			for tag in raw_tags:
				if typeof(tag) == TYPE_STRING:
					level_tags.append(tag)
					themed_tags.append(tag)
					if tag not in learned_tags:
						hasNewCards = true
					
					learned_tags.append(tag)
				else:
					results.write("Non-string tag found in themed level (dungeon %d)." % dungIndx)
					return false
			
			if(raw_tags.size() == 0):
				level_tags.append_array(learned_tags)

			# Create levels
			for j in range(levelCount):
				total_levels_so_far += 1
				
				var t = float(j) / max(1, levelCount)
				# We need to ease into goal speed, if it is linear the last level will get to fast without any preparation for it
				#t = ease(t, 2.0)
				t = pow(t, progression_curve)
				
				var speed:float = 0

				#If we are running through entirely new cards and the midgame speed is the same as the default setting
				if(hasNewCards and dungeon_start_speed == default_start_speed):
					speed = lerp(start_speed, dungeon_goal_speed, t)
				else:
					speed = lerp(dungeon_start_speed, dungeon_goal_speed, t)

				var levelType = Level.LevelType.STANDARD
				if(total_levels_so_far >= total_levels_in_dungeon):
					levelType = Level.LevelType.PRE_BOSS

				levels.append(Level.makeLevel(
					dungIndx,
					dungeon,
					level,
					speed,
					themed_tags, level_tags,
					levelType,
					verbose
				))


		# ---------------------------
		# BOSS LEVEL
		# ---------------------------
		#Get the tags from the last level
		if _last_level_tags.is_empty():
			_last_level_tags = learned_tags
		
		levels.append(Level.makeLevel(
			dungIndx,
			dungeon,
			null,
			dungeon_goal_speed,
			themed_tags, _last_level_tags,
			Level.LevelType.BOSS,
			verbose
		))
		print("Levels size: ",levels.size())

	return true
