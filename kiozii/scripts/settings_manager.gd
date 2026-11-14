extends Node

# GRAPHICS PRESET SIGNAL
signal graphics_preset_changed(preset_idx)

# SETTINGS DATA MODEL - DEFAULT LOW PRESET
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

var fullscreen: bool = false
var vsync: bool = false
var window_mode: int = 0
var resolution_idx: int = 2 # 1280x720 Windowed Default

# GRAPHICS CONFIG (DEFAULT LOW PRESET)
var graphics_preset: int = 0 # 0=LOW, 1=MEDIUM, 2=HIGH
var shadow_quality: int = 0 # 0=OFF, 1=LOW, 2=HIGH
var fog_enabled: bool = false
var bloom_enabled: bool = false
var msaa_quality: int = 0 # 0=DISABLED, 1=2X, 2=4X
var fps_cap: int = 60

# REBINDABLE ACTIONS AND DEFAULTS
const ACTIONS = ["move_left", "move_right", "jump", "shoot", "pause", "toggle_camera"]

# ACTION DISPLAY METADATA
const ACTION_NAMES = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump",
	"shoot": "Shoot",
	"pause": "Pause",
	"toggle_camera": "Toggle Camera"
}

# DEFAULT BINDING CODES
const DEFAULT_KEY_BINDINGS = {
	"move_left": {"type": "key", "code": 65, "second": 4194319},
	"move_right": {"type": "key", "code": 68, "second": 4194321},
	"jump": {"type": "key", "code": 32, "second": 87},
	"shoot": {"type": "mouse", "code": 1, "second": 74},
	"pause": {"type": "key", "code": 4194305, "second": 0},
	"toggle_camera": {"type": "key", "code": 67, "second": 0}
}

var custom_bindings: Dictionary = {}
const CONFIG_PATH = "user://kiozii_settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_all_settings()

func apply_all_settings() -> void:
	apply_audio_settings()
	apply_display_settings()
	apply_graphics_settings()
	apply_custom_bindings()

func apply_audio_settings() -> void:
	if AudioManager:
		AudioManager.set_volumes(master_volume, music_volume, sfx_volume)

func apply_display_settings() -> void:
	Engine.max_fps = fps_cap
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

	if shadow_quality == 0:
		RenderingServer.directional_shadow_atlas_set_size(512, false)
	elif shadow_quality == 1:
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
	else:
		RenderingServer.directional_shadow_atlas_set_size(2048, true)

func apply_preset(preset_idx: int) -> void:
	graphics_preset = preset_idx
	if preset_idx == 0: # LOW (DEFAULT)
		shadow_quality = 0
		fog_enabled = false
		bloom_enabled = false
		msaa_quality = 0
		vsync = false
		fps_cap = 60
	elif preset_idx == 1: # MEDIUM
		shadow_quality = 1
		fog_enabled = true
		bloom_enabled = true
		msaa_quality = 1
		vsync = true
		fps_cap = 60
	elif preset_idx == 2: # HIGH
		shadow_quality = 2
		fog_enabled = true
		bloom_enabled = true
		msaa_quality = 2
		vsync = true
		fps_cap = 60
	apply_graphics_settings()
	emit_signal("graphics_preset_changed", preset_idx)
	save_settings()

# INPUT REBINDING SYSTEM
func get_action_event_string(action: String) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events = InputMap.action_get_events(action)
	var names: Array[String] = []
	for ev in events:
		if ev is InputEventKey:
			var key_name = OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
			if key_name.is_empty():
				key_name = "Key %d" % ev.keycode
			names.append(key_name)
		elif ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				names.append("Left Click")
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				names.append("Right Click")
			elif ev.button_index == MOUSE_BUTTON_MIDDLE:
				names.append("Middle Click")
			else:
				names.append("Mouse %d" % ev.button_index)
	return " / ".join(names) if names.size() > 0 else "Unbound"

func rebind_action(action: String, new_event: InputEvent) -> String:
	var conflict_action = find_event_conflict(new_event, action)
	if not conflict_action.is_empty():
		return "Conflict: Already used by %s!" % ACTION_NAMES.get(conflict_action, conflict_action)

	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)

	if action == "move_left":
		var arrow = InputEventKey.new()
		arrow.keycode = KEY_LEFT
		if not is_event_matching(new_event, arrow):
			InputMap.action_add_event(action, arrow)
	elif action == "move_right":
		var arrow = InputEventKey.new()
		arrow.keycode = KEY_RIGHT
		if not is_event_matching(new_event, arrow):
			InputMap.action_add_event(action, arrow)
	elif action == "jump":
		var w_key = InputEventKey.new()
		w_key.keycode = KEY_W
		if not is_event_matching(new_event, w_key):
			InputMap.action_add_event(action, w_key)
	elif action == "shoot":
		var j_key = InputEventKey.new()
		j_key.keycode = KEY_J
		if not is_event_matching(new_event, j_key):
			InputMap.action_add_event(action, j_key)

	record_action_binding(action, new_event)
	save_settings()
	return ""

func find_event_conflict(event: InputEvent, current_action: String) -> String:
	for action in ACTIONS:
		if action == current_action:
			continue
		if not InputMap.has_action(action):
			continue
		for ev in InputMap.action_get_events(action):
			if is_event_matching(event, ev):
				return action
	return ""

func is_event_matching(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var code_a = a.physical_keycode if a.physical_keycode != 0 else a.keycode
		var code_b = b.physical_keycode if b.physical_keycode != 0 else b.keycode
		return code_a == code_b
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false

func record_action_binding(action: String, event: InputEvent) -> void:
	if event is InputEventKey:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		custom_bindings[action] = {"type": "key", "code": code}
	elif event is InputEventMouseButton:
		custom_bindings[action] = {"type": "mouse", "code": event.button_index}

func apply_custom_bindings() -> void:
	for action in custom_bindings.keys():
		if not InputMap.has_action(action):
			continue
		var data = custom_bindings[action]
		if not (data is Dictionary):
			continue
		var ev: InputEvent = null
		if data.get("type") == "key":
			var k = InputEventKey.new()
			k.keycode = data.get("code", 0)
			ev = k
		elif data.get("type") == "mouse":
			var m = InputEventMouseButton.new()
			m.button_index = data.get("code", 1)
			ev = m
		if ev:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, ev)
			if action == "move_left":
				var arrow = InputEventKey.new()
				arrow.keycode = KEY_LEFT
				if not is_event_matching(ev, arrow):
					InputMap.action_add_event(action, arrow)
			elif action == "move_right":
				var arrow = InputEventKey.new()
				arrow.keycode = KEY_RIGHT
				if not is_event_matching(ev, arrow):
					InputMap.action_add_event(action, arrow)
			elif action == "jump":
				var w_key = InputEventKey.new()
				w_key.keycode = KEY_W
				if not is_event_matching(ev, w_key):
					InputMap.action_add_event(action, w_key)
			elif action == "shoot":
				var j_key = InputEventKey.new()
				j_key.keycode = KEY_J
				if not is_event_matching(ev, j_key):
					InputMap.action_add_event(action, j_key)

func restore_default_controls() -> void:
	custom_bindings.clear()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var def = DEFAULT_KEY_BINDINGS.get(action, {})
		if def.get("type") == "key":
			var k = InputEventKey.new()
			k.keycode = def.get("code", 0)
			InputMap.action_add_event(action, k)
		elif def.get("type") == "mouse":
			var m = InputEventMouseButton.new()
			m.button_index = def.get("code", 1)
			InputMap.action_add_event(action, m)
		var sec = def.get("second", 0)
		if sec != 0:
			var sec_k = InputEventKey.new()
			sec_k.keycode = sec
			InputMap.action_add_event(action, sec_k)
	save_settings()

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("display", "resolution_idx", resolution_idx)
	cfg.set_value("display", "fps_cap", fps_cap)
	cfg.set_value("graphics", "preset", graphics_preset)
	cfg.set_value("graphics", "shadow", shadow_quality)
	cfg.set_value("graphics", "fog", fog_enabled)
	cfg.set_value("graphics", "bloom", bloom_enabled)
	cfg.set_value("graphics", "msaa", msaa_quality)
	cfg.set_value("controls", "bindings", custom_bindings)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		master_volume = cfg.get_value("audio", "master", 1.0)
		music_volume = cfg.get_value("audio", "music", 0.8)
		sfx_volume = cfg.get_value("audio", "sfx", 1.0)
		fullscreen = cfg.get_value("display", "fullscreen", false)
		vsync = cfg.get_value("display", "vsync", false) # DEFAULT FALSE
		resolution_idx = cfg.get_value("display", "resolution_idx", 2) # DEFAULT 1280x720
		fps_cap = cfg.get_value("display", "fps_cap", 60)
		graphics_preset = cfg.get_value("graphics", "preset", 0) # DEFAULT LOW
		shadow_quality = cfg.get_value("graphics", "shadow", 0)
		fog_enabled = cfg.get_value("graphics", "fog", false)
		bloom_enabled = cfg.get_value("graphics", "bloom", false)
		msaa_quality = cfg.get_value("graphics", "msaa", 0)
		custom_bindings = cfg.get_value("controls", "bindings", {})
	else:
		# FIRST LAUNCH DEFAULTS TO LOW PRESET
		apply_preset(0)
		save_settings()

func reset_to_defaults() -> void:
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0
	fullscreen = false
	vsync = false
	resolution_idx = 2 # 1280x720 Windowed
	fps_cap = 60
	apply_preset(0) # RESTORE LOW PRESET
	apply_all_settings()
	restore_default_controls()
	save_settings()
