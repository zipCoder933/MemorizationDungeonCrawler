extends Sprite3D
class_name WorldFlashCard

signal signal_new_flashcard
signal signal_flashcard_single_drill
signal signal_flashcard_finished_drill
signal signal_flashcard_answer_changed

var player:Player
@onready var card_ui: FlashcardUI = %CardUI

const GLOBAL_NODE = preload("uid://d364dmqkqu5a0")

func _ready():
	visible = false
