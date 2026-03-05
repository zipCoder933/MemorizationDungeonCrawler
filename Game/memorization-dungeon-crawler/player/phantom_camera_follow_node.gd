extends Node3D
class_name PhantomCameraFollowNode

var player: Node3D
var flashcard: WorldFlashCard
var tween: Tween
var length_tween: Tween

const PLAYER_LENGTH = 2.0
const FLASHCARD_LENGTH = 2.0

var length: float = 2.0

func _ready():
	player = Globals.get_player()

func _process(delta):
	var target_pos: Vector3

	if flashcard:
		target_pos = lerp(player.global_position, flashcard.get_look_target(), 0.5)
	else:
		target_pos = player.global_position

	_start_blend_to(target_pos)

func _start_blend_to(target_pos: Vector3):
	# Kill old tweens
	if tween:
		tween.kill()
	if length_tween:
		length_tween.kill()

	# Tween position
	tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.35) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Decide target length
	var target_length = FLASHCARD_LENGTH if flashcard else PLAYER_LENGTH

	# Tween length
	length_tween = create_tween()
	length_tween.tween_property(self, "length", target_length, 0.35) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
