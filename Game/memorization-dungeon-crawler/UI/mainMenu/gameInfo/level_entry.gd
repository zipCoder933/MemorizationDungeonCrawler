extends Panel
@onready var number: Label = %number
@onready var namePanel: Label = %name
@onready var play_button: Button = %playButton
@onready var lock_button: Button = %lockButton
@onready var panel: Panel = $"."
@onready var tags: Label = %tags


var level:Level
const A = Color(0.24, 0.24, 0.24, 0.718)

func set_details(level:Level, unlocked:bool):
	if(level.dungeon_index % 2 == 0):
		var style := StyleBoxFlat.new()
		style.bg_color = A
		add_theme_stylebox_override("panel", style)
	
	self.level = level
	number.text = str(level.level_index)
	namePanel.text = level.level_name
	tags.text = ", ".join(level.card_tags)
	if(level.levelType == Level.LevelType.BOSS):
		namePanel.text += " (Boss)";
	if(unlocked):
		lock_button.visible=false;
		play_button.visible=true;
	else:
		lock_button.visible=true;
		play_button.visible=false;


func _on_play_button_pressed() -> void:
	if(level != null):
		pass
		#Globals.st
