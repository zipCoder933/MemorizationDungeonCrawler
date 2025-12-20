extends Control
class_name HUD
@export var player:Player
@onready var damage_bar: ProgressBar = %DamageBar
@onready var keys_info: Label = %keysInfo
@onready var damage_bar_2: ProgressBar = %DamageBar2


@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel

@onready var card_ui: FlashcardUI = %CardUI
@onready var menu_panel: Panel = %MenuPanel
@onready var level_indicator: Label = %"level indicator"
@onready var loading_panel: Panel = $CanvasLayer/LoadingPanel
@onready var fps: Label = $fps
@onready var bossfight_stats: BossfightStats = $CanvasLayer/BossfightStats

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")
var fade_speed = 0.8

func panelsVisible():
	return game_over_panel.visible or victory_panel.visible\
		or menu_panel.visible

var current_question:Question
var bossfight_accuracy = 0
var animation_accuracy = 0
@onready var key_container: HBoxContainer = %keyContainer
@onready var key: TextureRect = %key
@onready var keys_hud: Panel = %keys_hud


func _key_obtained(keys:int):
	keys_info.text = "KEYS: "+str(keys)+" / "+str(Globals.totalArenas)
	var key_texture = load("res://assets/textures/key2.png")
	for i in keys:
		if(key_nodes.size() > i):
			key_nodes[i].texture = key_texture

func _global_fact_answering_mode(target2:WorldFlashCard):
	pass
	#keys_hud.visible=false

func _global_adventure_mode():
	pass
	#keys_hud.visible=true
	
var key_nodes = []

func _ready():
	fps.visible = false
	key.visible=false
	key_container.visible=false
	player.signal_key_obtained.connect(_key_obtained)
	bossfight_stats.visible=false
	game_over_panel.visible=false
	loading_panel.modulate.a = 1
	victory_panel.modulate.a = 0
	victory_panel.visible = false
	loading_panel.visible = true
	player.health_changed.connect(_player_health_changed)
	player.signal_health2_changed.connect(_player_health2_changed)
	Globals.signal_game_over.connect(_game_over)
	Globals.signal_show_bossfight_results.connect(bossfight_stats.complete_boss_fight)
	Globals.signal_victory.connect(_victory)
	Globals.fact_answering_mode.connect(_global_fact_answering_mode)
	Globals.adventure_mode.connect(_global_adventure_mode)
	
	_player_health_changed(player.health)
	_player_health2_changed(player.health2)
	
	if(SaveHandler.currentLevel != null and  SaveHandler.currentGame !=null):
		if(SaveHandler.currentLevel.levelType == Level.LevelType.BOSS):
			level_indicator.text = "LEVEL " +\
				str(SaveHandler.currentGame.completed_level+1) +" / "+\
				str(SaveHandler.currentGame.total_levels) +": "+\
			SaveHandler.currentLevel.boss_name + " ("+SaveHandler.currentLevel.level_name+")\n"+\
				"All keys must be obtained before conquering the boss!"
		else:
			level_indicator.text = "LEVEL " +\
				str(SaveHandler.currentGame.completed_level+1) +" / "+\
				str(SaveHandler.currentGame.total_levels) +": "+\
				SaveHandler.currentLevel.level_name;
			
			if SaveHandler.currentGame.completed_level < LevelsHandler.levels.size():
				var current_dungeon_indx = SaveHandler.currentLevel.dungeon_index
				var levels_until_next_dungeon = 0
				var next_dungeon = ""
				for i in range(SaveHandler.currentGame.completed_level, LevelsHandler.levels.size()):
					if LevelsHandler.levels[i].dungeon_index > current_dungeon_indx:
						next_dungeon = LevelsHandler.levels[i].level_name
						break
					else:
						levels_until_next_dungeon += 1
				level_indicator.text = level_indicator.text+"\n "+str(levels_until_next_dungeon) + " Levels until " + next_dungeon

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:
				menu_panel.visible = !menu_panel.visible
		elif event.keycode == KEY_CTRL:
				fps.visible = !fps.visible

func _process(delta):
	if(menu_panel.visible):#We cant have menu open if we are already in another menu
		if(victory_panel.visible or game_over_panel.visible or bossfight_stats.visible):
			menu_panel.visible = false
	
	fps.text = str(Engine.get_frames_per_second())+" fps"

	if(!key_container.visible):#Update the UI in the hud
		key_container.visible=true
		var total_keys = Globals.totalArenas
		var empty_key_texture = load("res://assets/textures/empty_key.png")
		for i in total_keys:
			var clone = key.duplicate()
			clone.texture = empty_key_texture
			clone.visible=true
			key_nodes.append(clone)
			key_container.add_child(clone)
		keys_info.text = "KEYS: "+str(player.keys)+" / "+str(Globals.totalArenas)
		
	card_ui.visible = Globals.has_flashcard()
	
	if(victory_panel.visible):
		victory_panel.modulate.a = victory_panel.modulate.a + (fade_speed * delta)
	
	loading_panel.modulate.a = loading_panel.modulate.a - (fade_speed * delta)
	if(loading_panel.modulate.a <= 0):
		loading_panel.visible = false
	

func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)

func _player_health2_changed(health:float):
	damage_bar_2.value = clamp(health, 0, Player.MAX_HEALTH)

func _game_over():
	game_over_panel.visible = true

@onready var victory_text: Label = %VictoryText
@onready var next: Button = $CanvasLayer/VictoryPanel/Next

func _victory():
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(_on_victory_timer_timeout)

func _on_victory_timer_timeout():
	print("Completed level: ",SaveHandler.currentGame.completed_level," levels: ",LevelsHandler.levels.size())
	if SaveHandler.currentGame.completed_level+1 >= LevelsHandler.levels.size():
		victory_text.text = "Congratulations!\n\"" + SaveHandler.currentGame.name + "\" Complete!"
		next.text = "Replay Final Level"
	else:
		victory_text.text = "Victory!"
		next.text = "Next Level"
	victory_panel.visible = true

func _on_button_pressed() -> void:
	Globals.go_home()
func _on_back_pressed() -> void:
	Globals.go_home()
func _on_home_pressed() -> void:
	Globals.go_home()
func _on_next_pressed() -> void:
	Globals.load_level()
func _on_try_again_pressed() -> void:
	Globals.load_level()
