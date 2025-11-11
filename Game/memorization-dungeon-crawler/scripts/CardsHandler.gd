class_name CardsHandler extends Node


const LevelsHandler = preload("uid://bte11e0fapqes")

#An easier alternative
static func randomCardInCurrentLevel() -> Card:
	if(SaveHandler.currentGame == null):
		assert(false, "Level is Null!")
	#Get the tags of the current level
	var tags = SaveHandler.currentLevel.cardTags
	#Get a random tag from that pile
	var tag = tags[randi_range(0,tags.size()-1)]
	#print("TAGS: ",tags)
	#Get a card from the tag
	return CardsHandler.randomCard(tag)
	
#======================================================

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
			var base_dir =  jsonFile.get_base_dir()
			
			for c in cards:
				var question = ""
				var isImage:bool = false
				
				if c.has("Question"):
					question = c["Question"]
				elif(c.has("QuestionImage")):
					isImage=true
					question = find_best_image_path(base_dir, c["QuestionImage"])
				
				var tags = c["Tags"]
				var type = c["Type"]
					
				var card = Card.new(base_dir, 
									type,
									question,
									isImage,
									str(c["Answer"]),  # 🪄 convert to string here
									tags
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



static func find_best_image_path(base_dir:String, base_path: String) -> String:
	var img := Image.new()

	# --- Clean the input path ---
	if(base_path.begins_with("res://")):
		base_path = base_path.lstrip("res://")
	
	if(base_path.begins_with("/")):
		base_path = base_path.lstrip("/")
		
	# --- Build both possibilities ---
	var possible_paths := [
		"res://" + base_dir + "/" +base_path,
		 base_dir + "/" +base_path
	]

	# --- Try both paths in order ---
	for path in possible_paths:
		var err = img.load(path)
		if err == OK:
			return path  # success! use this one

	# --- If nothing worked ---
	push_error("❌ Could not find valid image path for: " + base_path)
	return ""  # indicate failure
