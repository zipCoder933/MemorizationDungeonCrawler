class_name CardsHandler extends Node

#A hashmap (dictionary)
static var tag_dict = {}
static var player_mastery_dict = {}

#CONSTANTS
static var UNIQUE_IN_N_FACTS:int = 2; # We dont want cards to be repeated too quickly

func _init():
	pass

static var used_cards = {}  # tag -> list of last N used cards


static func card_count(tags:Array[String]) -> int:
	var size = 0
	for tag in tags:
		if(tag_dict.has(tag)):
			size += tag_dict[tag].size()
	return size

static func get_random_cards(card_tags:Array[String], quantity: int, unique_facts: int = 2) -> Array[Card]:
	var tags = card_tags
	
	var all_available: Array[Card] = []
	var card_tag_map: Dictionary = {}  # card -> tag

	# Collect available cards from all tags
	for tag in tags:
		if not tag_dict.has(tag):
			continue

		if not used_cards.has(tag):
			used_cards[tag] = []

		var available: Array[Card] = []
		for c in tag_dict[tag]:
			if not used_cards[tag].has(c):
				available.append(c)

		# If all cards used, reset memory
		if available.is_empty():
			used_cards[tag] = []
			available = tag_dict[tag].duplicate()

		# Add to global pool
		for c in available:
			all_available.append(c)
			card_tag_map[c] = tag

	if all_available.is_empty():
		return []

	var picked_cards: Array[Card] = []

	#If quantity is 0, set the quanity to all of them
	if(quantity == 0):
		unique_facts = 0 #Set unique facts to 0 (We dont need to worry about uniqueness if we are doing everything)
		quantity = all_available.size() 
	
	# Randomly pick across all available cards
	for i in range(quantity):
		if all_available.is_empty():
			break

		var index = randi() % all_available.size()
		var picked: Card = all_available[index]
		picked_cards.append(picked)

		var picked_tag = card_tag_map[picked]
		used_cards[picked_tag].append(picked)

		# Trim history for that tag
		if unique_facts > 0 and used_cards[picked_tag].size() > unique_facts:
			used_cards[picked_tag].pop_front()

		all_available.remove_at(index)

	return picked_cards



static func load_from_file(jsonFile):
	#reset everything first
	tag_dict={}
	player_mastery_dict = {}
	used_cards = {}
	
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
		print("Couldn't open cards.json file 😭")



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
