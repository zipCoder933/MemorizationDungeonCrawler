extends CanvasLayer
class_name BossfightStats

@onready var boss_name: Label = $BossfightStats/boss_name
@onready var boss_accuracy: Label = $BossfightStats/boss_accuracy
@onready var bossfight_stat_label: Label = $BossfightStats/bossfight_stat_label

var animation_accuracy:float = 0
var bossfight_accuracy:float = 0
var enemy:GoblinTrigger

func _ready():
	visible=false

func complete_boss_fight(_enemy:GoblinTrigger, _bossfight_accuracy):
	await get_tree().create_timer(4).timeout
	visible=true
	enemy = _enemy
	bossfight_stat_label.visible=false
	boss_accuracy.visible=false
	bossfight_accuracy = _bossfight_accuracy
	animation_accuracy = 0
	boss_name.text = SaveHandler.currentLevel.boss_name
	
	await get_tree().create_timer(2).timeout
	boss_accuracy.visible=true

func _process(delta):
	if(visible and boss_accuracy.visible):
		animation_accuracy = lerp(animation_accuracy, bossfight_accuracy, delta)
		boss_accuracy.text = "Accuracy: "+str(round(animation_accuracy))+"%"
		
		if(abs(bossfight_accuracy-animation_accuracy) < 0.5):
			animation_accuracy = bossfight_accuracy
			await get_tree().create_timer(1).timeout
			bossfight_stat_label.visible=true
			if(bossfight_accuracy >= 90):
				bossfight_stat_label.text = "Congratulations!"
				await get_tree().create_timer(5).timeout
				visible=false
				#enemy.die()
				Globals.victory_event()
			else:
				bossfight_stat_label.text = "Fail..."
				await get_tree().create_timer(5).timeout
				visible=false
				Globals.game_over_event()
