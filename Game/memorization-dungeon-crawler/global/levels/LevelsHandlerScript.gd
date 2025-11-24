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

static func load_from_file(file_path: String, results:GameJsonLoadInfo = GameJsonLoadInfo.new()) -> bool:
	#Reset everything first
	levels = []
	start_speed = 0
	goal_speed = 0
	level_index=0
	midgame_start_speed = 0
	midgame_goal_speed = 0
	
	print("Loading levels")
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		results.write("Failed to open JSON file!")
		return false
	
	var content = file.get_as_text()
	file.close()

	var result = JSON.parse_string(content)
	if not result:
		results.write("Failed to parse JSON")
		return false
	
	var json_data = result
	start_speed = json_data.get("starting_answer_speed_sec", 10)
	goal_speed = json_data.get("goal_answer_speed_sec", 2)
	
	midgame_start_speed = lerp(start_speed,goal_speed, 0.1)
	#The midgame goal is how fast we want to get at themed levels, like 10s or 1s,
	midgame_goal_speed = lerp(start_speed,goal_speed, 0.7)
	print("GAME SPEED (SEC): start=%2f; end=%2f; mid-start=%2f; mid-end=%2f;" % [start_speed, goal_speed, midgame_start_speed, midgame_goal_speed])
	
	var learnedTags:Array[String] = []
	const emptyArray: Array[String] = []
	
	# Load dungeons
	var dungeons = json_data.get("dungeons", [])
	for dungIndx in dungeons.size():
		var dungeon = dungeons[dungIndx]
		print("")
		
		#themed levels
		var themed_tags:Array[String] = [] #Contains only the new cards we are learning in this dungeon
		for themed_level in dungeon.get("themed_drill_levels", emptyArray):
			var levelCount = themed_level.get("count", 0)
			var levelTags:Array[String]
			levelTags.append_array(themed_level.get("tags", emptyArray))
			
			#If there are any level tags in themed tags
			var hasNewCards=false
			for tag in levelTags:
				if tag not in themed_tags:
					hasNewCards = true
					break
			#ANY NEW flashcards: Start at start_speed, progress to midgame_goal_speed 
			#NO NEW flashcards:  Start at midgame_start_speed, progress to midgame_goal_speed 
			for j in range(0, levelCount):
				var speed = 0
				if hasNewCards:
					speed = lerp(start_speed, midgame_goal_speed, j / levelCount)
				else:
					speed = lerp(midgame_start_speed, midgame_goal_speed, j / levelCount)
				
				levels.append(makeLevel(dungIndx, dungeon, speed, levelTags, levelTags, Level.LevelType.STANDARD))
			themed_tags.append_array(levelTags)
		
		#complete review levels
		#Start at midgame_start_speed, progress to midgame_goal_speed 
		learnedTags.append_array(themed_tags.duplicate())#Contains themed + all the others we learned in the past
		var goal = midgame_goal_speed
		if(dungIndx == dungeons.size() -1): #This is the final dungeon!
			goal = goal_speed
		
		var levelCount = dungeon.get("complete_drill_levels", 0)
		for i in range(levelCount):
			levels.append(makeLevel(dungIndx, dungeon, lerp(midgame_start_speed, goal, i / levelCount), themed_tags,learnedTags, Level.LevelType.STANDARD))
		
		#boss level
		levels.append(makeLevel(dungIndx, dungeon, goal, themed_tags,learnedTags, Level.LevelType.BOSS))

	return true


static func makeLevel(dungeonIndex:int, dungeon:Variant, speed_seconds:float, themed_tags:Array[String],\
					card_tags:Array[String], levelType: Level.LevelType) -> Level:
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
	print(level.toString())
	return level
