class_name Level
extends Node

enum LevelTheme {MACHINE, DUNGEON, JUNGLE}
enum LevelType { STANDARD, BOSS }


var level_name: String = ""
var theme: LevelTheme = LevelTheme.DUNGEON
var boss_name: String = ""          # default empty
var time_to_answer_sec: float = 30  # default 30 sec
var levelType: LevelType = LevelType.STANDARD
var cardTags: Array[String] = [] #If we dont specify tags, we just use all of them!!!

# Constructor
func _init(_name: String, _theme: String, _levelType: LevelType = LevelType.STANDARD, _boss_name: String = "", _time_to_answer_sec: float = 30.0, _cardTags: Array[String] = []):
	level_name = _name
	
	# Convert string to enum
	theme = LevelTheme.DUNGEON  # default fallback
	for themeName in LevelTheme.keys():
		if _theme.strip_edges().to_upper() == themeName.to_upper():
			theme = LevelTheme[themeName]
			break  # stop once we found a match
	
	levelType = _levelType
	boss_name = _boss_name
	time_to_answer_sec = _time_to_answer_sec
	cardTags = _cardTags.duplicate()


func toString() -> String:
	var theme_name = LevelTheme.keys()[theme]
	var type_name = LevelType.keys()[levelType]

	return "Level: \"%s\" |\t Time-Sec: %.2f |\t Theme: %s |\t Level-Type: %s |\t Boss-name: \"%s\" |\t Card-Tags: [%s]" % [
		level_name, time_to_answer_sec, theme_name, type_name, boss_name,  ", ".join(cardTags)
	]
