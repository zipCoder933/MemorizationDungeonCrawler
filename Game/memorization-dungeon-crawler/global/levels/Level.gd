
extends Node
class_name Level

enum LevelTheme {MACHINE, DUNGEON,JUNGLE,  LAVA,ANTARCTIC}
enum LevelType { STANDARD, BOSS }

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
const DEFAULT_ENEMY_CARD_COUNT = 20

# Constructor
func _init(_dungeon_index:int, _level_index:int, _name: String, _theme: String,\
		_card_review_number:float, _boss_card_review_number:float,\
		_levelType: LevelType = LevelType.STANDARD, _boss_name: String = "",\
		_time_to_answer_sec: float = 30.0, _themed_cards: Array[String] = [],\
		 _card_tags: Array[String] = [], _enemy_card_count:int = DEFAULT_ENEMY_CARD_COUNT):
	
	enemy_card_count = _enemy_card_count
	level_name = _name
	dungeon_index = _dungeon_index
	level_index = _level_index
	
	# Convert string to enum
	theme = LevelTheme.DUNGEON  # default fallback
	for themeName in LevelTheme.keys():
		if _theme.strip_edges().to_upper() == themeName.to_upper():
			theme = LevelTheme[themeName]
			break  # stop once we found a match
	
	card_count_multiplier = _card_review_number
	boss_card_count_multiplier = _boss_card_review_number
	levelType = _levelType
	boss_name = _boss_name
	time_to_answer_sec = _time_to_answer_sec
	
	card_tags = _card_tags.duplicate()
	themed_card_tags = _themed_cards.duplicate()
	
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
