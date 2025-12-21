extends Panel
@onready var number: Label = %number
@onready var namePanel: Label = %name
@onready var play_button: Button = %playButton
@onready var lock_button: Button = %lockButton
@onready var panel: Panel = $"."
@onready var tags: Label = %tags

@onready var message_box_container: MessageBox = $CanvasLayer/messageBoxContainer

var saveEntry:SaveEntry 
var level:Level
const A = Color(0.24, 0.24, 0.24, 0.718)

func set_details(saveEntry:SaveEntry , level:Level, unlocked:bool):
	if(level.dungeon_index % 2 == 0):
		var style := StyleBoxFlat.new()
		style.bg_color = A
		add_theme_stylebox_override("panel", style)
	
	self.level = level
	self.saveEntry = saveEntry
	number.text = str(level.level_index)
	
	
	if(level.card_tags.size() >= CardsHandler.tag_dict.size()):
		tags.text ="Everything"
	else:
		tags.text = ", ".join(level.card_tags)
		
	if(level.levelType == Level.LevelType.BOSS):
		namePanel.text = level.boss_name + " ("+level.level_name+")"
	else:
		namePanel.text = level.level_name

	if(unlocked):
		lock_button.visible=false;
		play_button.visible=true;
	else:
		lock_button.visible=true;
		play_button.visible=false;


func _on_play_button_pressed() -> void:
	if(level != null):
		var feedback:GameJsonLoadInfo = GameJsonLoadInfo.new()
		#Keep in mind that save.completedLevel is an array index, so 0 is the first level
		if Globals.start_game(saveEntry, true, level.level_index, feedback) == false:
			message_box_container.show_message("Error Loading Game", feedback.message)
