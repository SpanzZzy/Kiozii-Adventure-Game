extends CanvasLayer

@onready var health_hearts: HBoxContainer = $HUD/MarginTop/HBoxLeft/VBox/BoxHP/HBox/HeartsContainer
@onready var level_title: Label = $HUD/MarginTop/HBoxLeft/VBox/BoxLevel/LevelTitle
@onready var enemy_label: Label = $HUD/MarginTop/HBoxRight/BoxEnemies/EnemyLabel
@onready var crystal_label: Label = $HUD/MarginTop/HBoxRight/BoxCrystals/CrystalLabel
@onready var boss_hud: Control = $HUD/MarginTop/BossHUD
@onready var boss_hp_bar: ProgressBar = $HUD/MarginTop/BossHUD/VBox/ProgressBar
@onready var boss_hp_text: Label = $HUD/MarginTop/BossHUD/VBox/HBox/BossHpText

@onready var toast_banner: Control = $ToastBanner
@onready var toast_text: Label = $ToastBanner/Box/ToastText

@onready var pause_menu: Control = $PauseMenu
@onready var settings_modal: Control = $SettingsModal
@onready var game_over_menu: Control = $GameOverMenu
@onready var game_over_reason: Label = $GameOverMenu/Box/VBox/ReasonLabel

var prev_crystal_count: int = -1

func _ready() -> void:
	pause_menu.visible = false
	settings_modal.visible = false
	game_over_menu.visible = false
	toast_banner.visible = false
	boss_hud.visible = false

	GameManager.connect("health_changed", Callable(self, "_on_health_changed"))
	GameManager.connect("enemy_count_changed", Callable(self, "_on_enemy_count_changed"))
	GameManager.connect("boss_health_changed", Callable(self, "_on_boss_health_changed"))
	GameManager.connect("portal_unlocked", Callable(self, "_on_portal_unlocked"))
	GameManager.connect("game_over", Callable(self, "_on_game_over"))
	GameManager.connect("crystal_collected", Callable(self, "_on_crystal_collected"))
	GameManager.connect("checkpoint_reached", Callable(self, "_on_checkpoint_reached"))
	GameManager.connect("second_wind_activated", Callable(self, "_on_second_wind_activated"))
	GameManager.connect("achievement_unlocked", Callable(self, "_on_achievement_unlocked"))

	_on_health_changed(GameManager.player_current_health, GameManager.player_max_health)
	_on_enemy_count_changed(GameManager.enemies_remaining, GameManager.enemies_total)
	prev_crystal_count = GameManager.crystals_collected_level
	update_crystal_display(GameManager.crystals_collected_level, GameManager.crystals_total_level)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not game_over_menu.visible:
		if settings_modal.visible:
			settings_modal.hide()
		else:
			toggle_pause()

func set_level_info(level_num: int, title: String, is_boss: bool = false) -> void:
	level_title.text = "LVL %d: %s" % [level_num, title.to_upper()]
	if is_boss:
		$HUD/MarginTop/HBoxRight/BoxEnemies.visible = false
		$HUD/MarginTop/HBoxRight/BoxCrystals.visible = true
		boss_hud.visible = true
	else:
		$HUD/MarginTop/HBoxRight/BoxEnemies.visible = true
		$HUD/MarginTop/HBoxRight/BoxCrystals.visible = true
		boss_hud.visible = false

func show_toast(msg: String, color: Color = Color(0.2, 0.9, 0.5, 1.0)) -> void:
	toast_text.text = msg
	toast_text.add_theme_color_override("font_color", color)
	toast_banner.visible = true
	var tween = create_tween()
	toast_banner.modulate.a = 0.0
	tween.tween_property(toast_banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(2.2)
	tween.tween_property(toast_banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): toast_banner.visible = false)

func _on_portal_unlocked() -> void:
	show_toast("SUMMIT PORTAL UNLOCKED! REACH THE EXIT!", Color(0.2, 0.9, 0.5, 1.0))

func _on_checkpoint_reached(checkpoint_name: String) -> void:
	show_toast("ALTAR IGNITED: %s" % checkpoint_name.to_upper(), Color(0.2, 0.85, 1.0, 1.0))

func _on_second_wind_activated() -> void:
	show_toast("BOUNCE BACK! SECOND WIND SURGE!", Color(0.96, 0.75, 0.2, 1.0))

func update_crystal_display(current: int, total: int) -> void:
	crystal_label.text = "◆ CRYSTALS: %d/%d" % [current, total]

func _on_crystal_collected(current: int, total: int) -> void:
	update_crystal_display(current, total)
	if prev_crystal_count >= 0 and current > prev_crystal_count:
		show_toast("+1 RESOLVE CRYSTAL! (%d/%d)" % [current, total], Color(0.96, 0.95, 0.90, 1.0))
	prev_crystal_count = current

func _on_achievement_unlocked(_id: String, title: String, desc: String) -> void:
	show_toast("★ COMEBACK MEDAL: %s!\n%s" % [title, desc], Color(0.96, 0.85, 0.3, 1.0))

func _on_health_changed(current: int, maximum: int) -> void:
	for child in health_hearts.get_children():
		child.queue_free()
	
	for i in range(maximum):
		var heart = Label.new()
		heart.text = "♥"
		if i < current:
			heart.modulate = Color(0.96, 0.25, 0.37, 1.0)
		else:
			heart.modulate = Color(0.2, 0.25, 0.35, 1.0)
		health_hearts.add_child(heart)

func _on_enemy_count_changed(remaining: int, total: int) -> void:
	if remaining == 0:
		enemy_label.text = "PORTAL OPEN!"
		enemy_label.modulate = Color(0.2, 0.9, 0.5, 1.0)
	else:
		enemy_label.text = "FOES: %d / %d" % [remaining, total]
		enemy_label.modulate = Color(0.22, 0.74, 0.97, 1.0)

func _on_boss_health_changed(cur: int, max_hp: int) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur
	boss_hp_text.text = "%d/%d" % [cur, max_hp]
	if cur <= 16 and cur > 0:
		boss_hp_bar.modulate = Color(1.0, 0.2, 0.2, 1.0)
		boss_hp_text.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	else:
		boss_hp_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_game_over(reason: String) -> void:
	get_tree().paused = true
	game_over_reason.text = reason + "\nFall. Learn. Rise. Keep climbing!"
	game_over_menu.visible = true

func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused
	if not paused and settings_modal.visible:
		settings_modal.hide()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	settings_modal.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_settings_pressed() -> void:
	settings_modal.show()
	settings_modal.sync_from_manager()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
