extends CanvasLayer

# open-world 3d hud & map controller

@onready var health_hearts: HBoxContainer = $HUD/MarginTop/HBoxLeft/BoxHP/HeartsContainer
@onready var region_banner: Control = $HUD/MarginTop/Center/RegionBanner
@onready var region_title: Label = $HUD/MarginTop/Center/RegionBanner/RegionTitle
@onready var compass_label: Label = $HUD/MarginTop/Center/CompassBox/CompassLabel
@onready var crystal_label: Label = $HUD/MarginTop/HBoxRight/BoxCrystals/CrystalLabel
@onready var total_crystal_label: Label = $HUD/MarginTop/HBoxRight/BoxCrystals/TotalLabel

@onready var boss_hud: Control = $HUD/MarginTop/BossHUD
@onready var boss_hp_bar: ProgressBar = $HUD/MarginTop/BossHUD/VBox/ProgressBar
@onready var boss_hp_text: Label = $HUD/MarginTop/BossHUD/VBox/HBox/BossHpText

@onready var world_map: Control = $WorldMap
@onready var map_region_list: VBoxContainer = $WorldMap/Panel/VBox/Scroll/RegionList
@onready var toast_banner: Control = $ToastBanner
@onready var toast_text: Label = $ToastBanner/Box/ToastText

@onready var pause_menu: Control = $PauseMenu
@onready var settings_modal: Control = $SettingsModal
@onready var game_over_menu: Control = $GameOverMenu

var current_region_idx: int = 1
var player_node: Node3D = null

const REGION_NAMES = {
	1: "GREEN HIGHLANDS",
	2: "AUTUMN PEAKS",
	3: "ROCKY CANYON",
	4: "FROZEN RIDGE",
	5: "CRYSTAL MOUNTAINS",
	6: "EMBER SUMMIT",
	7: "THE FINAL SUMMIT"
}

func _ready() -> void:
	pause_menu.visible = false
	settings_modal.visible = false
	game_over_menu.visible = false
	toast_banner.visible = false
	boss_hud.visible = false
	world_map.visible = false
	
	GameManager.connect("health_changed", Callable(self, "_on_health_changed"))
	GameManager.connect("boss_health_changed", Callable(self, "_on_boss_health_changed"))
	GameManager.connect("game_over", Callable(self, "_on_game_over"))
	GameManager.connect("crystal_collected", Callable(self, "_on_crystal_collected"))
	GameManager.connect("crystal_pickup_notified", Callable(self, "_on_crystal_pickup_notified"))
	GameManager.connect("checkpoint_reached", Callable(self, "_on_checkpoint_reached"))
	GameManager.connect("second_wind_activated", Callable(self, "_on_second_wind_activated"))
	
	_on_health_changed(GameManager.player_current_health, GameManager.player_max_health)
	update_crystal_display()
	show_region_banner(1)

func _process(_delta: float) -> void:
	update_compass()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map") and not pause_menu.visible and not game_over_menu.visible:
		toggle_map()
	elif event.is_action_pressed("pause") and not game_over_menu.visible:
		if world_map.visible:
			toggle_map()
		elif settings_modal.visible:
			settings_modal.hide()
		else:
			toggle_pause()

func update_compass() -> void:
	if not is_inside_tree():
		return
	var vp = get_viewport()
	if not vp:
		return
	var cam = vp.get_camera_3d()
	if not cam or not cam.is_inside_tree():
		return
	var forward = -cam.global_transform.basis.z
	var angle_deg = rad_to_deg(atan2(forward.x, forward.z))
	if angle_deg < 0:
		angle_deg += 360.0
		
	# compass cardinal directions
	var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var idx = int(round(angle_deg / 45.0)) % 8
	var heading = dirs[idx]
	
	# summit indicator towards east (+x)
	var summit_dir = "▲ SUMMIT EAST"
	compass_label.text = "[ %s ]  %d°  %s" % [heading, int(angle_deg), summit_dir]

func toggle_map() -> void:
	world_map.visible = not world_map.visible
	if world_map.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		refresh_map_content()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func refresh_map_content() -> void:
	for child in map_region_list.get_children():
		child.queue_free()
		
	for i in range(1, 8):
		var reg_box = HBoxContainer.new()
		var lbl = Label.new()
		var is_cur = (i == current_region_idx)
		var prefix = "► " if is_cur else "  "
		var crys = GameManager.saved_crystals.get(str(i), [false, false, false])
		var count = 0
		for c in crys:
			if c == true:
				count += 1
		lbl.text = "%sREGION 0%d: %-20s  ◆ %d/3" % [prefix, i, REGION_NAMES[i], count]
		if is_cur:
			lbl.modulate = Color(0.2, 0.95, 0.5, 1.0)
		else:
			lbl.modulate = Color(0.85, 0.88, 0.95, 1.0)
		reg_box.add_child(lbl)
		map_region_list.add_child(reg_box)

func show_region_banner(region_num: int) -> void:
	current_region_idx = region_num
	var r_name = REGION_NAMES.get(region_num, "UNKNOWN REGION")
	region_title.text = "REGION 0%d: %s" % [region_num, r_name]
	region_banner.visible = true
	var tween = create_tween()
	region_banner.modulate.a = 0.0
	tween.tween_property(region_banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(region_banner, "modulate:a", 0.0, 0.4)
	
	boss_hud.visible = (region_num == 7)
	update_crystal_display()

func update_crystal_display() -> void:
	var reg_count = GameManager.get_region_crystal_count(current_region_idx)
	var total_count = GameManager.get_total_crystals_collected()
	crystal_label.text = "◆ CRYSTALS: %d/3" % reg_count
	total_crystal_label.text = "★ MOUNTAIN: %d/21" % total_count

func _on_crystal_collected(_cur: int, _total: int) -> void:
	update_crystal_display()

func _on_crystal_pickup_notified(uid: String, _reg_count: int, _total: int) -> void:
	update_crystal_display()
	show_toast("+1 RESOLVE CRYSTAL! [%s]" % uid.to_upper(), Color(0.96, 0.95, 0.90, 1.0))

func show_toast(msg: String, color: Color = Color(0.2, 0.9, 0.5, 1.0)) -> void:
	toast_text.text = msg
	toast_text.add_theme_color_override("font_color", color)
	toast_banner.visible = true
	var tween = create_tween()
	toast_banner.modulate.a = 0.0
	tween.tween_property(toast_banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(toast_banner, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): toast_banner.visible = false)

func _on_checkpoint_reached(checkpoint_name: String) -> void:
	show_toast("SHRINE IGNITED: %s" % checkpoint_name.to_upper(), Color(0.2, 0.85, 1.0, 1.0))

func _on_second_wind_activated() -> void:
	show_toast("BOUNCE BACK! SECOND WIND SURGE!", Color(0.96, 0.75, 0.2, 1.0))

func _on_health_changed(current: int, maximum: int) -> void:
	for child in health_hearts.get_children():
		child.queue_free()
	for i in range(maximum):
		var heart = Label.new()
		heart.text = "♥"
		if i < current:
			heart.modulate = Color(0.96, 0.25, 0.37, 1.0)
		else:
			heart.modulate = Color(0.25, 0.3, 0.4, 1.0)
		health_hearts.add_child(heart)

func _on_boss_health_changed(cur: int, max_hp: int) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur
	boss_hp_text.text = "%d/%d" % [cur, max_hp]

func toggle_pause() -> void:
	var will_pause = not get_tree().paused
	get_tree().paused = will_pause
	pause_menu.visible = will_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if will_pause else Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	settings_modal.show()
	settings_modal.sync_from_manager()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_game_over(reason: String) -> void:
	game_over_menu.visible = true
	var reason_lbl = game_over_menu.find_child("ReasonLabel", true, false)
	if reason_lbl:
		reason_lbl.text = reason
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
