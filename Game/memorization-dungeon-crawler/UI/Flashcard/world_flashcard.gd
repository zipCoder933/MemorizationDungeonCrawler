extends Sprite3D
class_name WorldFlashCard

var player:Player
@onready var card_ui: FlashcardUI = %CardUI

const GLOBAL_NODE = preload("uid://d364dmqkqu5a0")

func _ready():
	visible = false
