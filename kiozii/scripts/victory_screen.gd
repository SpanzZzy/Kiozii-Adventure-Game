extends Control

@onready var total_kills_val: Label = $CenterBox/VBox/BoxKills/VBoxInner/KillsVal

func _ready() -> void:
	total_kills_val.text = str(GameManager.total_kills_session)

func _on_replay_pressed() -> void:
	GameManager.total_kills_session = 0
	GameManager.start_level(0)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

