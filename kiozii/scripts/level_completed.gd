extends Control

@onready var title_label: Label = $CenterBox/VBox/Title
@onready var kills_label: Label = $CenterBox/VBox/StatsBox/HBox/VBoxKills/KillsVal
@onready var time_label: Label = $CenterBox/VBox/StatsBox/HBox/VBoxTime/TimeVal
@onready var crystals_label: Label = $CenterBox/VBox/StatsBox/HBox/VBoxCrystals/CrystalsVal
@onready var quote_label: Label = $CenterBox/VBox/BounceQuote

const BOUNCE_QUOTES = [
	"\"Every fall is another reason to rise.\"",
	"\"The summit belongs to those who keep climbing.\"",
	"\"Fall. Learn. Rise. Reach the summit.\"",
	"\"Your journey isn't over until you stop climbing.\""
]

func _ready() -> void:
	title_label.text = "SUMMIT %d CLEARED!" % (GameManager.current_level_idx + 1)
	kills_label.text = "%d / %d" % [GameManager.level_kills, GameManager.enemies_total]
	time_label.text = "%.1fs" % GameManager.level_time
	crystals_label.text = "%d / %d" % [GameManager.crystals_collected_level, GameManager.crystals_total_level]
	quote_label.text = BOUNCE_QUOTES[randi() % BOUNCE_QUOTES.size()]

func _on_next_pressed() -> void:
	GameManager.next_level()

func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
