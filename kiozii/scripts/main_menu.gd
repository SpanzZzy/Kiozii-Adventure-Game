extends Control

func _on_play_pressed() -> void:
	GameManager.total_kills_session = 0
	GameManager.start_level(0)

func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

