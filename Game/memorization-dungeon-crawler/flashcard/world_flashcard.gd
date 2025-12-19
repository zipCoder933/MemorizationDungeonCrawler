extends Sprite3D
class_name WorldFlashCard
@onready var look_target: Node3D = $LookTarget

signal signal_new_flashcard
signal signal_flashcard_single_drill
signal signal_flashcard_finished_drill
signal signal_flashcard_answer_changed

@export var parent:Node = null

var player:Player
@onready var card_ui: FlashcardUI = %CardUI

const GLOBAL_NODE = preload("uid://d364dmqkqu5a0")

func get_look_target() -> Vector3:
	return look_target.global_position

func get_time_elapsed_MS() -> int:
	return card_ui.get_time_elapsed_MS()

func _ready():
	visible = false
