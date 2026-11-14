extends Control

@onready var settings_modal = $SettingsModal
@onready var credits_modal = $CreditsModal

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_open_world_pressed() -> void:
	if AudioManager:
		AudioManager.play_jump()
	GameManager.total_kills_session = 0
	get_tree().change_scene_to_file("res://scenes/world/open_world_mountain.tscn")

func _on_play_pressed() -> void:
	if AudioManager:
		AudioManager.play_jump()
	GameManager.total_kills_session = 0
	GameManager.start_level(GameManager.current_level_idx)

func _on_levels_pressed() -> void:
	if AudioManager:
		AudioManager.play_jump()
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_jump()
	settings_modal.show()
	settings_modal.sync_from_manager()

func _on_credits_pressed() -> void:
	if AudioManager:
		AudioManager.play_jump()
	credits_modal.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
