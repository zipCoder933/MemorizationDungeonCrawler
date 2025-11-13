extends Panel
@onready var tag: Label = %tag
@onready var mastery: Label = %mastery
@onready var stats: Label = %stats

const GREEN = Color(0.0, 0.54, 0.0, 0.784)
const RED = Color(0.7, 0.0, 0.117, 0.784)


func set_details(info_tag:String, info:SaveEntry.CardMastery):
	tag.text = info_tag
	mastery.text = "Mastery: %d%%" % [
		int(info.get_mastery_level() * 100)
	]
	stats.text = "Tag Attempts: %d\nAvg Accuracy: %d%%\nAvg Speed: %.2fs" % [
		int(info.attempts),
		int(info.average_accuracy),
		info.average_speed / 1000.0
	]
	update_mastery_color(info.get_mastery_level())

func update_mastery_color(mastery_level: float) -> void:
	# mastery_level = 0.0 (bad) → 1.0 (perfect)
	var color = RED.lerp(GREEN, clamp(mastery_level, 0.0, 1.0))

	var style := StyleBoxFlat.new()
	style.bg_color = color
	add_theme_stylebox_override("panel", style)
