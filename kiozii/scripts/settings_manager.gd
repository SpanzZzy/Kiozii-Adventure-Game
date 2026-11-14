extends Node

# SETTINGS DATA MODEL
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

var fullscreen: bool = false
var vsync: bool = true
var window_mode: int = 0
var resolution_idx: int = 1

var graphics_preset: int = 1
var shadow_quality: int = 1
var fog_enabled: bool = true
var bloom_enabled: bool = true
var msaa_quality: int = 1

const CONFIG_PATH = "user://kiozii_settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_all_settings()

func apply_all_settings() -> void:
	apply_audio_settings()
	apply_display_settings()
	apply_graphics_settings()

func apply_audio_settings() -> void:
	if AudioManager:
		AudioManager.set_volumes(master_volume, music_volume, sfx_volume)

func apply_display_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolutions = [
			Vector2i(960, 540),
			Vector2i(1152, 648),
			Vector2i(1280, 720),
			Vector2i(1920, 1080)
		]
		if resolution_idx >= 0 and resolution_idx < resolutions.size():
			DisplayServer.window_set_size(resolutions[resolution_idx])

	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_graphics_settings() -> void:
	var vp = get_viewport()
	if not vp:
		return

	if msaa_quality == 0:
		vp.msaa_3d = Viewport.MSAA_DISABLED
	elif msaa_quality == 1:
		vp.msaa_3d = Viewport.MSAA_2X
	else:
		vp.msaa_3d = Viewport.MSAA_4X

	RenderingServer.directional_shadow_atlas_set_size(2048 if shadow_quality == 2 else (1024 if shadow_quality == 1 else 512), true)

func apply_preset(preset_idx: int) -> void:
	graphics_preset = preset_idx
	if preset_idx == 0:
		shadow_quality = 0
		fog_enabled = false
		bloom_enabled = false
		msaa_quality = 0
	elif preset_idx == 1:
		shadow_quality = 1
		fog_enabled = true
		bloom_enabled = true
		msaa_quality = 1
	elif preset_idx == 2:
		shadow_quality = 2
		fog_enabled = true
		bloom_enabled = true
		msaa_quality = 2
	apply_graphics_settings()
	save_settings()

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("display", "resolution_idx", resolution_idx)
	cfg.set_value("graphics", "preset", graphics_preset)
	cfg.set_value("graphics", "shadow", shadow_quality)
	cfg.set_value("graphics", "fog", fog_enabled)
	cfg.set_value("graphics", "bloom", bloom_enabled)
	cfg.set_value("graphics", "msaa", msaa_quality)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		master_volume = cfg.get_value("audio", "master", 1.0)
		music_volume = cfg.get_value("audio", "music", 0.8)
		sfx_volume = cfg.get_value("audio", "sfx", 1.0)
		fullscreen = cfg.get_value("display", "fullscreen", false)
		vsync = cfg.get_value("display", "vsync", true)
		resolution_idx = cfg.get_value("display", "resolution_idx", 1)
		graphics_preset = cfg.get_value("graphics", "preset", 1)
		shadow_quality = cfg.get_value("graphics", "shadow", 1)
		fog_enabled = cfg.get_value("graphics", "fog", true)
		bloom_enabled = cfg.get_value("graphics", "bloom", true)
		msaa_quality = cfg.get_value("graphics", "msaa", 1)

func reset_to_defaults() -> void:
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0
	fullscreen = false
	vsync = true
	resolution_idx = 1
	apply_preset(1)
	apply_all_settings()
	save_settings()
