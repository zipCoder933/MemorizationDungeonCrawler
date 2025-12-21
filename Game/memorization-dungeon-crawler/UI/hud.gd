extends Control
class_name HUD
@export var player:Player
@onready var damage_bar: ProgressBar = %DamageBar
@onready var keys_info: Label = %keysInfo
@onready var damage_bar_2: ProgressBar = %DamageBar2
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel
@onready var mute: Button = %mute
@onready var card_ui: FlashcardUI = %CardUI
@onready var menu_panel: Panel = %MenuPanel
@onready var level_indicator: Label = %"level indicator"
@onready var loading_panel: Panel = $CanvasLayer/LoadingPanel
@onready var fps: Label = $fps
@onready var bossfight_stats: BossfightStats = $CanvasLayer/BossfightStats
@onready var graphics: Button = %graphics

const LevelsHandler = preload("uid://bte11e0fapqes")
const SaveHandler = preload("uid://bgwdh30vglopu")
var fade_speed = 0.8

func panelsVisible():
	return game_over_panel.visible or victory_panel.visible\
		or menu_panel.visible

var current_question:Question
var bossfight_accuracy = 0
var animation_accuracy = 0
var currentLevel: int = 0;
var nextLevel: int = 0;
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
	currentLevel = SaveHandler.get_current_level().level_index
	fps.visible = false
	key.visible=false
	menu_panel.visible = false
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
	
	#Settings
	apply_graphics_level(SaveHandler.graphics_level)
	muteSound(SaveHandler.muted)
	
	_player_health_changed(player.health)
	_player_health2_changed(player.health2)
	
	if(SaveHandler.get_current_level() != null and  SaveHandler.currentGame !=null):
		if(SaveHandler.get_current_level().levelType == Level.LevelType.BOSS):
			level_indicator.text = "LEVEL " +\
				str(SaveHandler.get_current_level().level_index) +" / "+\
				str(SaveHandler.currentGame.total_levels) +": "+\
			SaveHandler.get_current_level().boss_name + " ("+SaveHandler.get_current_level().level_name+")\n"+\
				"All keys must be obtained before conquering the boss!"
		else:
			level_indicator.text = "LEVEL " +\
				str(SaveHandler.get_current_level().level_index) +" / "+\
				str(SaveHandler.currentGame.total_levels) +": "+\
				SaveHandler.get_current_level().level_name;
			
			if SaveHandler.currentGame.get_completed_level()-1 < LevelsHandler.levels.size():
				var current_dungeon_indx = SaveHandler.get_current_level().dungeon_index
				var levels_until_next_dungeon = 0
				var next_dungeon = ""
				for i in range(SaveHandler.get_current_level().level_index, LevelsHandler.levels.size()):
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
	currentLevel = SaveHandler.get_current_level().level_index #Current level array index
	nextLevel = currentLevel #Next level array index
	print("level indx: ",currentLevel,\
	" savefile level indx: ",SaveHandler.currentGame.get_completed_level(),\
	" levels size: ",LevelsHandler.levels.size())
	
	if currentLevel < LevelsHandler.levels.size():
		nextLevel = currentLevel + 1
		#Advance actual unlocked level if we reached that point
		if(SaveHandler.currentGame.get_completed_level() == currentLevel):
			SaveHandler.currentGame.set_completed_level(nextLevel)
			print("Progressing savefile completed level to ",SaveHandler.currentGame.get_completed_level())
	
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(_on_victory_timer_timeout)



func _on_victory_timer_timeout():
	if currentLevel >= LevelsHandler.levels.size():
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
	Globals.load_level(true, nextLevel)
func _on_try_again_pressed() -> void:
	Globals.load_level(true, SaveHandler.get_current_level().level_index)
	


func _on_mute_pressed() -> void:
	muteSound(!SaveHandler.muted)

func muteSound(is_muted:bool):
	var master_bus := AudioServer.get_bus_index("Master")
	if(is_muted):
		mute.text = "Sound: OFF"
	else:
		mute.text = "Sound: ON"
	
	SaveHandler.muted = is_muted
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	AudioServer.set_bus_mute(
		master_bus,
		is_muted
	)

func apply_graphics_level(level: int) -> void:
	var viewport := get_viewport()
	print("Setting graphics level to ", level)
	# Try to find WorldEnvironment in the current scene
	var we := get_tree().current_scene.find_child("WorldEnvironment", true, false)
	var env: Environment = we.environment if we and we.environment else null
	
	#Defaults
	Engine.max_fps = 0
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	if env:
		env.ssao_enabled = false
		env.glow_enabled = false
		env.volumetric_fog_enabled = false
		env.sdfgi_enabled = false

	match level:
		0:
			viewport.scaling_3d_scale = 0.5
			graphics.text = "Graphics: Potato"
		1:
			viewport.scaling_3d_scale = 0.6
			graphics.text = "Graphics: Low"
		2:
			viewport.scaling_3d_scale = 0.7
			graphics.text = "Graphics: Medium"
		3: 
			viewport.scaling_3d_scale = 0.8
			graphics.text = "Graphics: Default"
		4: 
			viewport.scaling_3d_scale = 0.9
			graphics.text = "Graphics: High"
		5:
			viewport.scaling_3d_scale = 1.0
			#viewport.msaa_3d = Viewport.MSAA_2X
			#if env:
				#env.glow_enabled = true
				#env.volumetric_fog_enabled = true
			graphics.text = "Graphics: Max"



func _on_graphics_pressed() -> void:
	SaveHandler.graphics_level = (SaveHandler.graphics_level + 1) % 6
	SaveHandler.save_to_file(Globals.SAVE_FILE)
	apply_graphics_level(SaveHandler.graphics_level)
