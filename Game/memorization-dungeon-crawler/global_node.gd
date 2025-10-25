extends Node
class_name GlobalEvents

signal fact_answering_mode
signal adventure_mode
signal game_over
#signal game_started
#signal player_died
#signal item_collected(item_name)

func _ready():
	print("Global loaded!")
	#GlobalEvents.game_started.connect(_on_game_started)
	#GlobalEvents.item_collected.connect(_on_item_collected)

#func _on_game_started():
	#print("The game has started!")
#
#func _on_item_collected(item_name):
	#print("Collected item:", item_name)
