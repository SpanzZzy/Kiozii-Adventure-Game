extends Control

# settings menu controller
@onready var master_slider = $CenterBox/VBox/TabContainer/Audio/Grid/MasterSlider
@onready var music_slider = $CenterBox/VBox/TabContainer/Audio/Grid/MusicSlider
@onready var sfx_slider = $CenterBox/VBox/TabContainer/Audio/Grid/SFXSlider

@onready var fullscreen_check = $CenterBox/VBox/TabContainer/Display/Grid/FullscreenCheck
@onready var vsync_check = $CenterBox/VBox/TabContainer/Display/Grid/VSyncCheck
@onready var res_option = $CenterBox/VBox/TabContainer/Display/Grid/ResOption

@onready var preset_option = $CenterBox/VBox/TabContainer/Graphics/Grid/PresetOption
@onready var shadow_option = $CenterBox/VBox/TabContainer/Graphics/Grid/ShadowOption
@onready var msaa_option = $CenterBox/VBox/TabContainer/Graphics/Grid/MSAAOption
@onready var fog_check = $CenterBox/VBox/TabContainer/Graphics/Grid/FogCheck
@onready var bloom_check = $CenterBox/VBox/TabContainer/Graphics/Grid/BloomCheck

# controls nodes
@onready var controls_grid = $CenterBox/VBox/TabContainer/Controls/VBoxInner/GridControls
@onready var controls_status = $CenterBox/VBox/TabContainer/Controls/VBoxInner/StatusLabel

var awaiting_action: String = ""
var action_labels: Dictionary = {}

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	populate_options()
	build_controls_ui()
	sync_from_manager()

func populate_options() -> void:
	res_option.clear()
	res_option.add_item("960 x 540 (Compact)", 0)
	res_option.add_item("1152 x 648 (Standard)", 1)
	res_option.add_item("1280 x 720 (HD)", 2)
	res_option.add_item("1920 x 1080 (FHD)", 3)

	preset_option.clear()
	preset_option.add_item("Performance (Low)", 0)
	preset_option.add_item("Balanced (Medium)", 1)
	preset_option.add_item("High Quality", 2)

	shadow_option.clear()
	shadow_option.add_item("Off", 0)
	shadow_option.add_item("Low (1024)", 1)
	shadow_option.add_item("High (2048)", 2)

	msaa_option.clear()
	msaa_option.add_item("Disabled", 0)
	msaa_option.add_item("2x MSAA", 1)
	msaa_option.add_item("4x MSAA", 2)

func build_controls_ui() -> void:
	for child in controls_grid.get_children():
		child.queue_free()
	action_labels.clear()

	for action in SettingsManager.ACTIONS:
		var name_lbl = Label.new()
		name_lbl.text = SettingsManager.ACTION_NAMES.get(action, action)
		name_lbl.custom_minimum_size = Vector2(120, 0)
		controls_grid.add_child(name_lbl)

		var bind_lbl = Label.new()
		bind_lbl.text = SettingsManager.get_action_event_string(action)
		bind_lbl.custom_minimum_size = Vector2(170, 0)
		bind_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.95, 1.0))
		controls_grid.add_child(bind_lbl)
		action_labels[action] = bind_lbl

		var rebind_btn = Button.new()
		rebind_btn.text = "REBIND"
		rebind_btn.custom_minimum_size = Vector2(80, 28)
		rebind_btn.pressed.connect(func(): start_rebinding(action))
		controls_grid.add_child(rebind_btn)

func refresh_control_labels() -> void:
	for action in action_labels.keys():
		action_labels[action].text = SettingsManager.get_action_event_string(action)

func start_rebinding(action: String) -> void:
	awaiting_action = action
	controls_status.text = "Press any key or mouse button for [%s]..." % SettingsManager.ACTION_NAMES.get(action, action)
	controls_status.add_theme_color_override("font_color", Color(0.96, 0.75, 0.2, 1.0))

func _input(event: InputEvent) -> void:
	if awaiting_action.is_empty():
		return

	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
		# escape cancellation
		if event is InputEventKey and event.keycode == KEY_ESCAPE and awaiting_action != "pause":
			awaiting_action = ""
			controls_status.text = "Rebinding cancelled."
			controls_status.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
			get_viewport().set_input_as_handled()
			return

		var err = SettingsManager.rebind_action(awaiting_action, event)
		if err.is_empty():
			controls_status.text = "Successfully bound [%s]!" % SettingsManager.ACTION_NAMES.get(awaiting_action, awaiting_action)
			controls_status.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5, 1.0))
			refresh_control_labels()
		else:
			controls_status.text = err
			controls_status.add_theme_color_override("font_color", Color(0.96, 0.25, 0.35, 1.0))

		awaiting_action = ""
		get_viewport().set_input_as_handled()

func sync_from_manager() -> void:
	if not SettingsManager:
		return
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0

	fullscreen_check.button_pressed = SettingsManager.fullscreen
	vsync_check.button_pressed = SettingsManager.vsync
	res_option.selected = SettingsManager.resolution_idx

	preset_option.selected = SettingsManager.graphics_preset
	shadow_option.selected = SettingsManager.shadow_quality
	msaa_option.selected = SettingsManager.msaa_quality
	fog_check.button_pressed = SettingsManager.fog_enabled
	bloom_check.button_pressed = SettingsManager.bloom_enabled
	refresh_control_labels()

func _on_master_slider_value_changed(val: float) -> void:
	SettingsManager.master_volume = val / 100.0
	SettingsManager.apply_audio_settings()
	SettingsManager.save_settings()

func _on_music_slider_value_changed(val: float) -> void:
	SettingsManager.music_volume = val / 100.0
	SettingsManager.apply_audio_settings()
	SettingsManager.save_settings()

func _on_sfx_slider_value_changed(val: float) -> void:
	SettingsManager.sfx_volume = val / 100.0
	SettingsManager.apply_audio_settings()
	SettingsManager.save_settings()

func _on_fullscreen_check_toggled(toggled: bool) -> void:
	SettingsManager.fullscreen = toggled
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()

func _on_vsync_check_toggled(toggled: bool) -> void:
	SettingsManager.vsync = toggled
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()

func _on_res_option_item_selected(index: int) -> void:
	SettingsManager.resolution_idx = index
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()

func _on_preset_option_item_selected(index: int) -> void:
	SettingsManager.apply_preset(index)
	sync_from_manager()

func _on_shadow_option_item_selected(index: int) -> void:
	SettingsManager.shadow_quality = index
	SettingsManager.apply_graphics_settings()
	SettingsManager.save_settings()

func _on_msaa_option_item_selected(index: int) -> void:
	SettingsManager.msaa_quality = index
	SettingsManager.apply_graphics_settings()
	SettingsManager.save_settings()

func _on_fog_check_toggled(toggled: bool) -> void:
	SettingsManager.fog_enabled = toggled
	SettingsManager.save_settings()

func _on_bloom_check_toggled(toggled: bool) -> void:
	SettingsManager.bloom_enabled = toggled
	SettingsManager.save_settings()

func _on_restore_controls_pressed() -> void:
	SettingsManager.restore_default_controls()
	controls_status.text = "Restored default controls."
	controls_status.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5, 1.0))
	refresh_control_labels()

func _on_reset_btn_pressed() -> void:
	SettingsManager.reset_to_defaults()
	controls_status.text = "Reset all settings to default."
	sync_from_manager()

func _on_close_btn_pressed() -> void:
	awaiting_action = ""
	hide()
	closed.emit()
