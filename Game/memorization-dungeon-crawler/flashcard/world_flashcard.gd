extends Sprite3D
class_name WorldFlashCard
@onready var look_target: Node3D = $LookTarget

signal signal_new_flashcard
signal signal_flashcard_single_drill
signal signal_flashcard_finished_drill

@export var fightMusic:AudioStreamOggVorbis
@export var parent:Node = null

var player:Player
var drill_submit_time_ms:int
@onready var card_ui: FlashcardUI = %CardUI

const GLOBAL_NODE = preload("uid://d364dmqkqu5a0")

func get_look_target() -> Vector3:
	return look_target.global_position

func get_time_elapsed_MS() -> int:
	return card_ui.get_time_elapsed_MS()

func get_time_limit_MS() -> int:
	return card_ui.get_time_limit_MS()

func _ready():
	visible = false
