extends Node
class_name FlashcardDrillResults

var flashcard_node: WorldFlashCard

var deck_size: int
var themed_deck_size: int

var succeeded: float
var themed_succeeded: float

func get_themed_accuracy() -> float:
	return themed_succeeded / themed_deck_size if themed_deck_size > 0 else 1
	
func get_accuracy() -> float:
	return succeeded / deck_size if deck_size > 0 else 1

func _init(_deck_size: int, _themed_deck_size: int, _succeeded: float, _themed_succeeded: float, _node: WorldFlashCard):
	deck_size = _deck_size
	themed_deck_size = _themed_deck_size
	succeeded = _succeeded
	themed_succeeded = _themed_succeeded
	flashcard_node = _node

func toString() -> String:
	return "FlashcardDrillResults(succeeded=%s, themed=%s, deck_size=%s, themed_deck_size=%s, node=%s)" % [
		str(succeeded),
		str(themed_succeeded),
		str(deck_size),
		str(themed_deck_size),
		str(flashcard_node)
	]
