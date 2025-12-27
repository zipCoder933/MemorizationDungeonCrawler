
extends Node
class_name Level

enum LevelTheme {MACHINE, DUNGEON,JUNGLE,  LAVA,ANTARCTIC}
enum LevelType { STANDARD, BOSS,PRACTICE }

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

var enemy_card_count:int
var card_count_multiplier:float = 1 #How many times we want to review each card in this level
var boss_card_count_multiplier:float = 2 #How many times we want to review each card during a bossfight
var boss_level_arenas:float

static func makePracticeLevel(level:Level) -> Level:
	var new_level:Level = Level.make_level(level)
	new_level.level_index=-1
	new_level.theme = LevelTheme.DUNGEON
	new_level.levelType = LevelType.PRACTICE
	new_level.enemy_card_count *= 100
	new_level.time_to_answer_sec = LevelsHandler.midgame_start_speed
	return new_level

#For levelsHandlerScript
static func makeLevel(dungeonIndex:int, dungeon:Variant, speed_seconds:float, themed_tags:Array[String],\
					card_tags:Array[String], levelType: Level.LevelType, verbose:bool) -> Level:
	LevelsHandler.level_index += 1
	LevelsHandler._last_level_tags = card_tags.duplicate()
	
	# Convert string to enum
	var theme = LevelTheme.DUNGEON  # default fallback
	var _theme = JsonUtils.get_string(dungeon,"theme", "")
	for themeName in LevelTheme.keys():
		if _theme.strip_edges().to_upper() == themeName.to_upper():
			theme = LevelTheme[themeName]
			break  # stop once we found a match
	
	var level =  Level.new(
		dungeonIndex,
		LevelsHandler.level_index,
		JsonUtils.get_string(dungeon,"name", ""),
		theme,
		JsonUtils.get_float(dungeon,"card_count_multiplier", 1.5), #Card count multiplier
		JsonUtils.get_float(dungeon,"boss_card_count_multiplier", 2), #boss card cound multiplier
		levelType,
		JsonUtils.get_string(dungeon,"boss_name", ""),
		speed_seconds,  # or any logic to set time_to_answer_sec
		themed_tags.duplicate(),
		card_tags.duplicate(),
		JsonUtils.get_int(dungeon,"enemy_card_count", 15),
		JsonUtils.get_int(dungeon,"boss_level_arenas", 3)
	)
	if(verbose):
		print(level.toString())
	return level



static func make_level(level: Level) -> Level:
	return Level.new(
		level.dungeon_index,
		level.level_index,
		level.level_name,
		level.theme,       # Convert enum back to string if needed
		level.card_count_multiplier,
		level.boss_card_count_multiplier,
		level.levelType,    # Convert enum back to string if needed
		level.boss_name,
		level.time_to_answer_sec,
		level.themed_card_tags.duplicate(),
		level.card_tags.duplicate(),
		level.enemy_card_count,
		level.boss_level_arenas
	)


func _init(_dungeon_index:int,
		_level_index:int,\
		_name: String,\
		_theme: LevelTheme,\
		_card_count_multiplier:float, \
		_boss_card_count_multiplier:float,\
		_levelType: LevelType, 
		_boss_name: String,\
		_time_to_answer_sec: float, \
		_themed_cards: Array[String],\
		_card_tags: Array[String],\
		_enemy_card_count:int,\
		_boss_level_arenas:int):
	
	self.boss_level_arenas = _boss_level_arenas
	self.enemy_card_count = _enemy_card_count
	self.level_name = _name
	self.theme = _theme
	self.dungeon_index = _dungeon_index
	self.level_index = _level_index
	self.card_count_multiplier = _card_count_multiplier
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

	return "Level %s; (Dungeon %s: \"%s\"): |\t Time-Sec: %.2f |\t Theme: %s |\t Level-Type: %s |\t Boss-name: \"%s\" |\t Card-Tags: [%s] |\t Theme-Card-Tags: [%s] |\t Level Card X: %s; Boss Card X: %s" % [
		level_index,dungeon_index, level_name, time_to_answer_sec, theme_name, type_name, boss_name,  ", ".join(card_tags),", ".join(themed_card_tags), card_count_multiplier, boss_card_count_multiplier
	]
