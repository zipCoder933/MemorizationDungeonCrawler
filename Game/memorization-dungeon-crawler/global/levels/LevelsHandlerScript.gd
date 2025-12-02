extends Node

#An array of Levels
static var levels: Array[Level] = []
static var start_speed
static var goal_speed
static var midgame_start_speed
static var midgame_goal_speed
#---
static var level_index:int = 0
func _ready():
	pass
	#load_levels("res://data/games/multiplication/level.json")  # path to your JSON file
	#print("Loaded %d levels" % levels.size())

static func load_from_file(file_path: String, results:GameJsonLoadInfo = GameJsonLoadInfo.new(), verbose:bool = false) -> bool:
	# Reset globals safely
	levels = []
	start_speed = 0
	goal_speed = 0
	level_index = 0
	midgame_start_speed = 0
	midgame_goal_speed = 0
	
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
	goal_speed  = JsonUtils.get_float(json_data, "goal_answer_speed_sec", 2.0)

	var default_start_speed = lerp(start_speed, goal_speed, JsonUtils.get_float(json_data, "midgame_start_speed_percent", 0.1))
	var default_goal_speed  = lerp(start_speed, goal_speed, JsonUtils.get_float(json_data, "midgame_goal_speed_percent", 0.7))
	midgame_start_speed = default_start_speed
	midgame_goal_speed  = default_goal_speed
	

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

	var learnedTags:Array[String] = []
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
		if(dungeon.has("start_speed_percent")):
			var lerp_value =  JsonUtils.get_float(dungeon, "start_speed_percent",0)
			print("Start lerp ",lerp_value)
			midgame_start_speed = lerp(start_speed, goal_speed,lerp_value)
		else:
			midgame_start_speed = default_start_speed
		
		if(dungeon.has("goal_speed_percent")):
			var lerp_value =  JsonUtils.get_float(dungeon, "goal_speed_percent",0)
			print("End lerp ",lerp_value)
			midgame_goal_speed  = lerp(start_speed, goal_speed,lerp_value)
		else:
			midgame_goal_speed = default_goal_speed
		
		if(verbose):
			print("Dungeon speed: start=",midgame_start_speed,"; end=",midgame_goal_speed)

		# ---------------------------
		# THEMATIC DRILL LEVELS
		# ---------------------------
		var themed_drills = dungeon.get("themed_drill_levels", [])
		if typeof(themed_drills) != TYPE_ARRAY:
			results.write("'themed_drill_levels' in dungeon %d must be an array." % dungIndx)
			return false

		var themed_tags:Array[String] = []

		for themed_level in themed_drills:
			if typeof(themed_level) != TYPE_DICTIONARY:
				results.write("A themed level in dungeon %d is not a dictionary." % dungIndx)
				return false

			var levelCount = JsonUtils.get_int(themed_level, "count", 0)
			if levelCount < 0:
				results.write("Negative 'count' in themed level (dungeon %d)." % dungIndx)
				return false

			# Validate tags
			var raw_tags = themed_level.get("tags", [])
			if typeof(raw_tags) != TYPE_ARRAY:
				results.write("The 'tags' field in a themed level (dungeon %d) is not an array." % dungIndx)
				return false

			# Ensure every tag is a string
			var levelTags:Array[String] = []
			for tag in raw_tags:
				if typeof(tag) == TYPE_STRING:
					levelTags.append(tag)
				else:
					results.write("Non-string tag found in themed level (dungeon %d)." % dungIndx)
					return false

			# Determine whether they contain new learning tags
			var hasNewCards := false
			for tag in levelTags:
				if tag not in themed_tags:
					hasNewCards = true
					break

			# Create themed levels
			for j in range(levelCount):
				var t = float(j) / max(1, levelCount)
				var speed = lerp(midgame_start_speed, midgame_goal_speed, t)
				#If we are running through entirely new cards and the midgame speed is the same as the default setting
				if(hasNewCards and midgame_start_speed == default_start_speed):
					speed = lerp(start_speed, midgame_goal_speed, t)



				levels.append(makeLevel(
					dungIndx,
					dungeon,
					speed,
					levelTags,
					levelTags,
					Level.LevelType.STANDARD, verbose
				))

			themed_tags.append_array(levelTags)

		# ---------------------------
		# COMPLETE DRILL LEVELS
		# ---------------------------
		learnedTags.append_array(themed_tags.duplicate())

		var final_is_last = dungIndx == dungeons.size() - 1
		var complete_goal = goal_speed if final_is_last else midgame_goal_speed


		var completeCount = JsonUtils.get_int(dungeon, "complete_drill_levels", 0)
		if completeCount < 0:
			results.write("'complete_drill_levels' must not be negative (dungeon %d)." % dungIndx)
			return false

		for i in range(completeCount):
			var t = float(i) / max(1, completeCount)
			var speed = lerp(midgame_start_speed, complete_goal, t)

			levels.append(makeLevel(
				dungIndx,
				dungeon,
				speed,
				themed_tags,
				learnedTags,
				Level.LevelType.STANDARD, verbose
			))

		# ---------------------------
		# BOSS LEVEL
		# ---------------------------
		levels.append(makeLevel(
			dungIndx,
			dungeon,
			complete_goal,
			themed_tags,
			learnedTags,
			Level.LevelType.BOSS, verbose
		))

	return true



static func makeLevel(dungeonIndex:int, dungeon:Variant, speed_seconds:float, themed_tags:Array[String],\
					card_tags:Array[String], levelType: Level.LevelType, verbose:bool) -> Level:
	#var typed_cards: Array[String] = []
	#for c in card_tags:
		#typed_cards.append(str(c))  # ensure every element is a string
	level_index+=1
	var level =  Level.new(dungeonIndex, level_index,
		dungeon.get("name", ""),
		dungeon.get("theme", ""),
		dungeon.get("card_review_number", 3),
		dungeon.get("boss_card_review_number", 2),
		levelType,
		dungeon.get("boss_name", ""),
		speed_seconds,  # or any logic to set time_to_answer_sec
		themed_tags.duplicate(),
		card_tags.duplicate()
	)
	if(verbose):
		print(level.toString())
	return level
