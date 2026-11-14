extends Control

@onready var title_label: Label = $CenterBox/VBox/Title
@onready var kills_label: Label = $CenterBox/VBox/StatsBox/HBox/VBoxKills/KillsVal
@onready var time_label: Label = $CenterBox/VBox/StatsBox/HBox/VBoxTime/TimeVal

func _ready() -> void:
	title_label.text = "SUMMIT %d CLEARED!" % (GameManager.current_level_idx + 1)
	kills_label.text = "%d / %d" % [GameManager.level_kills, GameManager.enemies_total]
	time_label.text = "%.1fs" % GameManager.level_time

func _on_next_pressed() -> void:
	GameManager.next_level()

func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

