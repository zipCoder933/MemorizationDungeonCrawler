extends Control

@export var player:Player
@onready var damage_bar: ProgressBar = $CanvasLayer/DamageBar

func _ready():
	player.health_changed.connect(_player_health_changed)
	
func _player_health_changed(health:float):
	damage_bar.value = clamp(health, 0, Player.MAX_HEALTH)
