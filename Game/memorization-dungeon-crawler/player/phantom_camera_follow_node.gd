extends Node3D
class_name PhantomCameraFollowNode

var player: Node3D
var flashcard: WorldFlashCard
var tween: Tween

func _ready():
	player = Globals.get_player()

func _process(delta):
	# always compute the desired target
	var target_pos: Vector3

	if flashcard:
		# sweet beautiful midpoint
		target_pos = lerp(player.global_position, flashcard.get_look_target(), .7)
	else:
		# just the player again
		target_pos = player.global_position

	# start blending only when the target changes
	_start_blend_to(target_pos)
	

func _start_blend_to(target_pos: Vector3):
	# kill any old tween—no zombie tweens allowed
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.35) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_OUT)
