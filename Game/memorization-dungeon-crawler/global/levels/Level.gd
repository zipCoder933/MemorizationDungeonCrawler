class_name Level
extends Node

enum LevelTheme {MACHINE, DUNGEON,JUNGLE,  LAVA,ANTARCTIC}
enum LevelType { STANDARD, BOSS }


var level_name: String = ""
var theme: LevelTheme = LevelTheme.DUNGEON
var boss_name: String = ""          # default empty
var time_to_answer_sec: float = 30  # default 30 sec
var levelType: LevelType = LevelType.STANDARD
var card_tags: Array[String] = [] #If we dont specify tags, we just use all of them!!!
var card_review_number:int = 1 #How many times we want to review each card

# Constructor
func _init(_name: String, _theme: String, _card_review_number:int, _levelType: LevelType = LevelType.STANDARD, _boss_name: String = "", _time_to_answer_sec: float = 30.0, _card_tags: Array[String] = []):
	level_name = _name
	
	# Convert string to enum
	theme = LevelTheme.DUNGEON  # default fallback
	for themeName in LevelTheme.keys():
		if _theme.strip_edges().to_upper() == themeName.to_upper():
			theme = LevelTheme[themeName]
			break  # stop once we found a match
	
	card_review_number = _card_review_number
	levelType = _levelType
	boss_name = _boss_name
	time_to_answer_sec = _time_to_answer_sec
	card_tags = _card_tags.duplicate()
	
	#remove duplicates of card_tags
	var trimmed_card_tags:Array[String] = []
	for card_tag in card_tags:
		if(!trimmed_card_tags.has(card_tag)):
			trimmed_card_tags.append(card_tag)
	card_tags = trimmed_card_tags
	#print("Level: ",toString())


func toString() -> String:
	var theme_name = LevelTheme.keys()[theme]
	var type_name = LevelType.keys()[levelType]

	return "Level: \"%s\" |\t Time-Sec: %.2f |\t Theme: %s |\t Level-Type: %s |\t Boss-name: \"%s\" |\t Card-Tags: [%s]" % [
		level_name, time_to_answer_sec, theme_name, type_name, boss_name,  ", ".join(card_tags)
	]
