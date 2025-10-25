extends Node

static var levels: Array = []
static var seed

static var start_speed
static var goal_speed
static var midgame_start_speed
static var midgame_goal_speed

func _ready():
	load_levels("res://data/games/multiplication/level.json")  # path to your JSON file
	print("Loaded %d levels" % levels.size())

static func load_levels(file_path: String):
	print("Loading levels")
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		print("Failed to open JSON file!")
		return
	
	var content = file.get_as_text()
	file.close()

	var result = JSON.parse_string(content)
	if not result:
		print("Failed to parse JSON")
		return
	
	var json_data = result
	var learnedTags:Array[String] = []
	
	# Seed or timing info
	seed = json_data.get("seed", 0)
	start_speed = json_data.get("starting_answer_speed_sec", 10)
	goal_speed = json_data.get("goal_answer_speed_sec", 2)
	
	midgame_start_speed = lerp(start_speed,goal_speed, 0.1)
	midgame_goal_speed = lerp(start_speed,goal_speed, 0.5)
	print("GAME SPEED (SEC): start=%2f; end=%2f; mid-start=%2f; mid-end=%2f;" % [start_speed, goal_speed, midgame_start_speed, midgame_goal_speed])
	
	const emptyArray: Array[String] = []
	
	# Load dungeons
	for dungeon in json_data.get("dungeons", []):
		print("")
		learnedTags.append_array(dungeon.get("themed_cards", emptyArray))
		
		#themed levels
		var levelCount = dungeon.get("themed_drill_levels", 0)
		for i in range(levelCount):
			levels.append(makeLevel(dungeon, lerp(start_speed, midgame_goal_speed, i / levelCount), dungeon.get("themed_cards", emptyArray), Level.LevelType.STANDARD))
		
		#complete review levels
		levelCount = dungeon.get("complete_drill_levels", 0)
		for i in range(levelCount):
			levels.append(makeLevel(dungeon, lerp(midgame_start_speed, midgame_goal_speed, i / levelCount), learnedTags, Level.LevelType.STANDARD))
		
		#boss level
		levels.append(makeLevel(dungeon, midgame_goal_speed, learnedTags, Level.LevelType.BOSS))
	
	print("")
	# Load final dungeon
	var final = json_data.get("final_dungeon", null)
	if final:
		var levelCount = final.get("complete_drill_levels", 0)
		for i in range(levelCount):
			levels.append(makeLevel(
				final,  
				lerp(midgame_start_speed, midgame_goal_speed, i / levelCount), 
				learnedTags, 
				Level.LevelType.STANDARD))
		levels.append(makeLevel(final, goal_speed, learnedTags, Level.LevelType.BOSS))
	
	#print("\nlevels:")
	#for l in levels:
		#print(l.toString())

static func makeLevel(dungeon:Variant, speed_seconds:float, cardTags:Array, levelType: Level.LevelType) -> Level:

	
	var typed_cards: Array[String] = []
	for c in cardTags:
		typed_cards.append(str(c))  # ensure every element is a string
	
	var level =  Level.new(
		dungeon.get("name", "Unknown Dungeon"),
		dungeon.get("theme", "Unknown Theme"),
		levelType,
		dungeon.get("boss_name", ""),
		speed_seconds,  # or any logic to set time_to_answer_sec
		typed_cards
	)
	print(level.toString())
	return level
