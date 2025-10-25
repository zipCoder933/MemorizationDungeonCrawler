class_name CardsHandler extends Node

#A hashmap (dictionary)
static var tag_dict = {}
static var player_mastery_dict = {}

#CONSTANTS
static var UNIQUE_IN_N_FACTS:int = 2; # We dont want cards to be repeated too quickly

func _init():
	pass
	#openCards("res://persistentData/multiplication/cards.json")


static var used_cards = {}  # tag -> list of last N used cards
static func randomCard(tag: String) -> Card:
	if not tag_dict.has(tag):
		return null  # Tag doesn't exist

	# Initialize used_cards list for this tag if needed
	if not used_cards.has(tag):
		used_cards[tag] = []

	# Get available cards that haven't been used recently
	var available = []
	for c in tag_dict[tag]:
		if not c in used_cards[tag]:
			available.append(c)

	# If all cards are in used_cards, reset memory
	if available.size() == 0:
		used_cards[tag] = []
		available = tag_dict[tag].duplicate()

	# Pick a random card from available ones
	var picked = available[randi() % available.size()]

	# Add to used_cards, and trim to last N
	used_cards[tag].append(picked)
	if used_cards[tag].size() > UNIQUE_IN_N_FACTS:
		used_cards[tag].pop_front()  # remove oldest

	return picked


static func load_from_file(jsonFile):
	#reset everything first
	tag_dict={}
	player_mastery_dict = {}
	
	var file = FileAccess.open(jsonFile, FileAccess.READ)
	if file:#If read succesfully
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		if data:#If we can get json data
			var cards = data["Cards"]
			print("Loading Deck:")
			for c in cards:
				var card = Card.new(
									c["Type"],
									c["Question"],
									str(c["Answer"]),  # 🪄 convert to string here
									c["Tags"]
								)

				for tag in card.tags:
					if not tag_dict.has(tag):
						tag_dict[tag] = []
					tag_dict[tag].append(card)

			# 🎉 Example: print all cards grouped by tag
			for tag in tag_dict.keys():
				print("Tag:", tag)
				for card in tag_dict[tag]:
					print("   ", card.toString())
		else:
			print("Oops! JSON parsing failed!")
	else:
		print("Couldn't open file 😭")
