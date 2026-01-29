
extends Node
class_name Level

enum LevelTheme {MACHINE, DUNGEON,JUNGLE,  LAVA,ANTARCTIC}
enum LevelType { STANDARD, PRE_BOSS, BOSS, PRACTICE }

var dungeon_index:int
var level_index:int
var level_name: String = ""

var theme: LevelTheme = LevelTheme.DUNGEON
var boss_name: String = ""          # default empty
var time_to_answer_sec: float = 30  # default 30 sec
var levelType: LevelType = LevelType.STANDARD

 #If we dont specify tags, we just use all of them!!!
var card_tags: Array[String] = []
var themed_card_tags: Array[String] = []

var arena_count:int
var enemy_card_count:int
var boss_card_count_multiplier:float = 2 #How many times we want to review each card during a bossfight

static func makePracticeLevel(level:Level) -> Level:
	var new_level:Level = Level.make_level(level)
	new_level.level_index=-1
	new_level.theme = LevelTheme.DUNGEON
	new_level.levelType = LevelType.PRACTICE
	new_level.enemy_card_count = min(new_level.enemy_card_count*100,2500)
	new_level.time_to_answer_sec = LevelsHandler.start_speed
	return new_level

#For levelsHandlerScript
static func makeLevel(dungeonIndex:int,\
					dungeonJson:Variant,\
					levelJson:Variant,\
					speed_seconds:float,\
					themed_tags:Array[String],\
					card_tags:Array[String],\
					levelType: Level.LevelType,\
					verbose:bool) -> Level:
						
	LevelsHandler.level_index += 1
	LevelsHandler._last_level_tags = card_tags.duplicate()
	
	# Convert string to enum
	var theme = LevelTheme.DUNGEON  # default fallback
	var _theme = JsonUtils.get_string(dungeonJson,"theme", "")
	for themeName in LevelTheme.keys():
		if _theme.strip_edges().to_upper() == themeName.to_upper():
			theme = LevelTheme[themeName]
			break  # stop once we found a match
	
	var arena_count = 4;
	if(levelType == LevelType.BOSS):
		arena_count = JsonUtils.get_int(dungeonJson,"boss_level_arenas", 3)
	else:
		var arena_range = JsonUtils.get_int_array(levelJson,"arena_count", [3,6])
		if(arena_range.size() >=2):
			arena_count = randi_range(arena_range[0],arena_range[1])
			
		if(levelType == LevelType.PRE_BOSS):
			arena_count = max(clamp(arena_count*2,9,15),arena_count)
	
	var enemy_card_count = JsonUtils.get_int(levelJson,"enemy_card_count", JsonUtils.get_int(dungeonJson,"enemy_card_count", 15))
	
	var level =  Level.new(
		dungeonIndex,
		LevelsHandler.level_index,
		JsonUtils.get_string(dungeonJson,"name", ""),
		theme,
		arena_count,
		JsonUtils.get_float(dungeonJson,"boss_card_count_multiplier", 2), #boss card cound multiplier
		levelType,
		JsonUtils.get_string(dungeonJson,"boss_name", ""),
		speed_seconds,  # or any logic to set time_to_answer_sec
		themed_tags.duplicate(),
		card_tags.duplicate(),
		enemy_card_count,
	)
	if(verbose):
		print(level.toString())
	return level


#factory method for duplicating a level
static func make_level(level: Level) -> Level:
	return Level.new(
		level.dungeon_index,
		level.level_index,
		level.level_name,
		level.theme,       # Convert enum back to string if needed
		level.arena_count,
		level.boss_card_count_multiplier,
		level.levelType,    # Convert enum back to string if needed
		level.boss_name,
		level.time_to_answer_sec,
		level.themed_card_tags.duplicate(),
		level.card_tags.duplicate(),
		level.enemy_card_count
	)

func is_standard_level():
	return levelType == LevelType.STANDARD or levelType == LevelType.PRE_BOSS;

func _init(_dungeon_index:int,
		_level_index:int,\
		_name: String,\
		_theme: LevelTheme,\
		_arena_count:int, \
		_boss_card_count_multiplier:float,\
		_levelType: LevelType, 
		_boss_name: String,\
		_time_to_answer_sec: float, \
		_themed_cards: Array[String],\
		_card_tags: Array[String],\
		_enemy_card_count:int):
	
	self.enemy_card_count = _enemy_card_count
	self.level_name = _name
	self.theme = _theme
	self.dungeon_index = _dungeon_index
	self.level_index = _level_index
	self.arena_count = _arena_count
	self.boss_card_count_multiplier = _boss_card_count_multiplier
	self.levelType = _levelType
	self.boss_name = _boss_name
	self.time_to_answer_sec = _time_to_answer_sec
	self.card_tags = _card_tags.duplicate()
	self.themed_card_tags = _themed_cards.duplicate()
	
	#remove duplicates of card_tags
	var trimmed_card_tags:Array[String] = []
	for card_tag in card_tags:
		if(!trimmed_card_tags.has(card_tag)):
			trimmed_card_tags.append(card_tag)
	card_tags = trimmed_card_tags
	
	var trimmed_themed_card_tags:Array[String] = []
	for card_tag in themed_card_tags:
		if(!trimmed_themed_card_tags.has(card_tag)):
			trimmed_themed_card_tags.append(card_tag)
	themed_card_tags = trimmed_themed_card_tags


func toString() -> String:
	var theme_name = LevelTheme.keys()[theme]
	var type_name = LevelType.keys()[levelType]
	var ret := "Level %s; (Dungeon %s: \"%s\"):\tTime: %.2fs\tArenas: %s\tEnemy cards: %s\tTheme: %s\tType: %s\tTags: [%s]\tThemed-Tags: [%s]" % [
		level_index,
		dungeon_index,
		level_name,
		time_to_answer_sec,
		arena_count,
		enemy_card_count,
		theme_name,
		type_name,
		", ".join(card_tags),
		", ".join(themed_card_tags)
	]

	if levelType == LevelType.BOSS:
		ret += "\tBoss Card X: %s" % boss_card_count_multiplier

	return ret
