extends CanvasLayer
class_name BossfightStats

@onready var boss_name: Label = %boss_name
@onready var bossfight_stat_label: Label = %bossfight_stat_label


@onready var themed_accuracy_container: VBoxContainer = $BossfightStats/VBoxContainer/themed_accuracy_container
@onready var themed_accuracy_label: Label = %themed_accuracy_label
@onready var themed_accuracy: Label = %themed_accuracy

@onready var overall_accuracy_container: VBoxContainer = $BossfightStats/VBoxContainer/overall_accuracy_container
@onready var overall_accuracy_label: Label = %overall_accuracy_label
@onready var overall_accuracy: Label = %overall_accuracy

@onready var success: AudioStreamPlayer = $success
@onready var fail: AudioStreamPlayer = $fail
@onready var pound: AudioStreamPlayer = $pound


var animation_speed:float = 0.78
var animation_accuracy: float = 0
var enemy: GoblinTrigger
var results: FlashcardDrillResults

var show_phase := "none" # "themed" → "overall" → "done"

func _ready():
	visible = false

func complete_boss_fight(_enemy: GoblinTrigger, _results: FlashcardDrillResults):
	visible = true
	pound.play(0)
	enemy = _enemy
	results = _results

	# Hide everything at first
	bossfight_stat_label.visible = false
	themed_accuracy_label.visible = false
	overall_accuracy_container.visible = false
	themed_accuracy_container.visible = false
	
	themed_accuracy_label.text = "~~ "+ ", ".join(SaveHandler.get_current_level().themed_card_tags) +" ~~"
	animation_accuracy = 0
	boss_name.text = SaveHandler.get_current_level().boss_name

	# Start with themed accuracy
	await get_tree().create_timer(2).timeout
	pound.play(0)
	show_phase = "themed"
	themed_accuracy_label.visible = true
	print("Bossfight data: ",_results)


func _process(delta):
	if not visible:
		return

	if show_phase == "themed":
		themed_accuracy_container.visible=true
		_show_accuracy_animation(
			results.get_themed_accuracy()*100,
			themed_accuracy,
			"overall",
			delta
		)

	elif show_phase == "overall":
		overall_accuracy_container.visible=true
		_show_accuracy_animation(
			results.get_accuracy()*100,
			overall_accuracy,
			"done",
			delta
		)

	elif show_phase == "done":
		#get_tree().create_timer(1).timeout.connect(func():
		_show_final_result()


func _show_accuracy_animation(target_accuracy: float, label: Label, next_phase: String, delta:float):
	animation_accuracy = lerp(animation_accuracy, target_accuracy, animation_speed*delta)
	label.text = "Accuracy: "+str(round(animation_accuracy)) + "%"

	if abs(target_accuracy - animation_accuracy) < 0.5:
		# Snap final value
		label.text = "Accuracy: "+str(round(target_accuracy)) + "%"
		animation_accuracy = 0
		# Move to next phase
		show_phase = next_phase
		if next_phase == "overall":
			pound.play(0)
			get_tree().create_timer(1.5).timeout.connect(func():
				#pound.play(0)
				overall_accuracy_label.visible = true;
				)
		elif next_phase == "done":
			get_tree().create_timer(2).timeout.connect(func():
				bossfight_stat_label.visible = true;
				)


func _show_final_result():
	bossfight_stat_label.visible=true

	if results.get_themed_accuracy() >= .9 and results.get_accuracy() >= .9:
		success.play(0)
		bossfight_stat_label.text = "Congratulations!"
		if enemy:
			enemy.die()
		get_tree().create_timer(4).timeout.connect(func():
			visible = false
			Globals.victory_event())
	else:
		fail.play(0)
		bossfight_stat_label.text = "Fail..."
		get_tree().create_timer(4).timeout.connect(func():
			visible = false
			Globals.game_over_event())

	# Prevent repeating
	show_phase = "done-finished"
