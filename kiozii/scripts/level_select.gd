extends Control

@onready var grid: GridContainer = $CenterBox/VBox/Grid

func _ready() -> void:
	var summit_names = [
		"Green Highlands",
		"Autumn Peaks",
		"Rocky Canyon",
		"Frozen Ridge",
		"Crystal Mountains",
		"Ember Summit",
		"The Final Summit"
	]
	
	for i in range(1, GameManager.total_levels + 1):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 60)
		var is_unlocked = i <= GameManager.unlocked_level
		var is_cleared = GameManager.completed_levels.has(i)
		
		btn.disabled = not is_unlocked
		var status_str = "★ CLEARED" if is_cleared else ("OPEN" if is_unlocked else "🔒 LOCKED")
		btn.text = "SUMMIT %02d\n%s\n[%s]" % [i, summit_names[i - 1], status_str]
		
		var lvl_idx = i - 1
		btn.pressed.connect(func(): GameManager.start_level(lvl_idx))
		grid.add_child(btn)

func _on_unlock_all_pressed() -> void:
	GameManager.unlock_all_levels()
	get_tree().reload_current_scene()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

