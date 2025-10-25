extends Control

@export var player:Player
@onready var damage_bar: ProgressBar = $CanvasLayer/DamageBar
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel

func _ready():
	player.health_changed.connect(_player_health_changed)
	Globals.game_over.connect(_game_over)
	
func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)

func _game_over():
	game_over_panel.visible = true
