extends Node

# GAME MANAGER & COMEBACK PROGRESSION
signal health_changed(new_health, max_health)
signal enemy_count_changed(remaining, total)
signal boss_health_changed(current_hp, max_hp)
signal portal_unlocked
signal level_completed(clear_time, kills, total, crystals_collected, crystals_total)
signal game_over(reason)
signal crystal_collected(current_count, total_count)
signal crystal_pickup_notified(crystal_uid, region_count, total_count)
signal checkpoint_reached(pos_name)
signal second_wind_activated
signal achievement_unlocked(ach_id, ach_title, ach_desc)

var current_level_idx: int = 0
var current_level_index: int:
	get: return current_level_idx
	set(val): current_level_idx = val
var unlocked_level: int = 1
var completed_levels: Array = []
var total_levels: int = 7

var player_max_health: int = 5
var player_current_health: int = 5

var enemies_remaining: int = 0
var enemies_total: int = 0
var level_kills: int = 0
var total_kills_session: int = 0
var level_time: float = 0.0
var is_level_active: bool = false
var portal_is_open: bool = false

# BOUNCE BACK STATS
var has_respawned_this_level: bool = false
var damage_taken_this_level: int = 0
var crystals_collected_level: int = 0
var crystals_total_level: int = 3

# CRYSTAL PERSISTENCE PER LEVEL: ARRAY OF BOOLS [C0, C1, C2]
var saved_crystals: Dictionary = {}
var saved_open_world_crystals: Dictionary = {}
var collected_crystal_uids: Dictionary = {}

# ACTIVE CHECKPOINT POSITION
var current_checkpoint_pos: Vector3 = Vector3.ZERO
var has_custom_checkpoint: bool = false

# ACHIEVEMENTS PERSISTENCE
var unlocked_achievements: Dictionary = {}
const ACHIEVEMENTS_DATA = {
	"never_give_up": {
		"title": "NEVER GIVE UP",
		"desc": "Bounced back and conquered a summit after falling into the chasm!"
	},
	"crystal_seeker": {
		"title": "CRYSTAL SEEKER",
		"desc": "Gathered every glowing Resolve Crystal on the mountain!"
	},
	"untouchable": {
		"title": "UNTOUCHABLE",
		"desc": "Conquered a summit with zero damage taken!"
	},
	"high_altitude": {
		"title": "HIGH ALTITUDE",
		"desc": "Reached the treacherous heights of Summit 6!"
	},
	"ultimate_comeback": {
		"title": "THE ULTIMATE COMEBACK",
		"desc": "Overcame the Summit Overlord to claim the Seven Summits!"
	}
}

const SAVE_PATH = "user://kiozii_progress.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progress()

func _process(delta: float) -> void:
	if is_level_active and not get_tree().paused:
		level_time += delta

func reset_for_level(enemy_count: int, is_boss: bool = false) -> void:
	player_current_health = player_max_health
	enemies_total = enemy_count
	enemies_remaining = enemy_count
	level_kills = 0
	level_time = 0.0
	is_level_active = true
	portal_is_open = (enemy_count == 0 and not is_boss)
	has_respawned_this_level = false
	damage_taken_this_level = 0
	has_custom_checkpoint = false
	current_checkpoint_pos = Vector3.ZERO
	
	# INITIALIZE CRYSTALS FOR CURRENT LEVEL (3 PER LEVEL FOR ALL 7 SUMMITS)
	crystals_total_level = 3
	var lvl_key = str(current_level_idx + 1)
	var lvl_saved = saved_crystals.get(lvl_key, [false, false, false])
	var count = 0
	for c in lvl_saved:
		if c == true:
			count += 1
	crystals_collected_level = count
	
	emit_signal("health_changed", player_current_health, player_max_health)
	emit_signal("enemy_count_changed", enemies_remaining, enemies_total)
	emit_signal("crystal_collected", crystals_collected_level, crystals_total_level)
	if portal_is_open:
		emit_signal("portal_unlocked")

func is_crystal_collected(c_id: int) -> bool:
	var lvl_key = str(current_level_idx + 1)
	var lvl_saved = saved_crystals.get(lvl_key, [false, false, false])
	if c_id >= 0 and c_id < lvl_saved.size():
		return lvl_saved[c_id] == true
	return false

# OPEN WORLD REGION CRYSTAL RESOLUTION & TRACKING
func is_crystal_unique_collected(uid: String, reg_num: int, c_id: int) -> bool:
	if collected_crystal_uids.get(uid, false) == true:
		return true
	if reg_num > 0:
		return is_region_crystal_collected(reg_num, c_id)
	return is_crystal_collected(c_id)

func register_crystal_collected(uid: String, reg_num: int, c_id: int) -> void:
	if is_crystal_unique_collected(uid, reg_num, c_id):
		return
	collected_crystal_uids[uid] = true

	if reg_num > 0:
		var lvl_key = str(reg_num)
		if not saved_open_world_crystals.has(lvl_key):
			saved_open_world_crystals[lvl_key] = [false, false, false]
		if c_id >= 0 and c_id < saved_open_world_crystals[lvl_key].size():
			saved_open_world_crystals[lvl_key][c_id] = true
	else:
		var lvl_key = str(current_level_idx + 1)
		if not saved_crystals.has(lvl_key):
			saved_crystals[lvl_key] = [false, false, false]
		if c_id >= 0 and c_id < saved_crystals[lvl_key].size():
			saved_crystals[lvl_key][c_id] = true
		crystals_collected_level = mini(crystals_collected_level + 1, crystals_total_level)

	save_progress()
	if AudioManager:
		AudioManager.play_crystal()

	emit_signal("crystal_pickup_notified", uid, get_region_crystal_count(reg_num), get_total_crystals_collected())
	emit_signal("crystal_collected", get_region_crystal_count(reg_num), 3)

func is_region_crystal_collected(reg_num: int, c_id: int) -> bool:
	var lvl_key = str(reg_num)
	var lvl_saved = saved_open_world_crystals.get(lvl_key, [false, false, false])
	if c_id >= 0 and c_id < lvl_saved.size():
		return lvl_saved[c_id] == true
	return false

func on_region_crystal_collected(reg_num: int, c_id: int) -> void:
	var uid = "summit_%02d_crystal_%02d" % [reg_num, c_id + 1]
	register_crystal_collected(uid, reg_num, c_id)

func get_region_crystal_count(reg_num: int) -> int:
	var list = saved_open_world_crystals.get(str(reg_num), [false, false, false])
	var count = 0
	for c in list:
		if c == true:
			count += 1
	return count

# OPEN WORLD REGION SWITCH AND TOTAL STATS
func get_total_crystals_collected() -> int:
	var total = 0
	for lvl in range(1, 8):
		var list = saved_open_world_crystals.get(str(lvl), [false, false, false])
		for c in list:
			if c == true:
				total += 1
	return total

func set_current_region(region_num: int) -> void:
	current_level_idx = clampi(region_num - 1, 0, 6)
	crystals_total_level = 3
	var lvl_key = str(current_level_idx + 1)
	var lvl_saved = saved_open_world_crystals.get(lvl_key, [false, false, false])
	var count = 0
	for c in lvl_saved:
		if c == true:
			count += 1
	crystals_collected_level = count
	# NOTE: DO NOT EMIT PICKUP TOAST WHEN SWITCHING REGIONS

func on_crystal_collected(c_id: int) -> void:
	var uid = "summit_%02d_crystal_%02d" % [current_level_idx + 1, c_id + 1]
	register_crystal_collected(uid, 0, c_id)

func set_checkpoint(pos: Vector3, checkpoint_name: String = "Summit Altar") -> void:
	current_checkpoint_pos = pos
	has_custom_checkpoint = true
	if AudioManager:
		AudioManager.play_checkpoint()
	emit_signal("checkpoint_reached", checkpoint_name)

func has_active_checkpoint() -> bool:
	return has_custom_checkpoint

func get_checkpoint_position() -> Vector3:
	return current_checkpoint_pos

func trigger_second_wind() -> void:
	has_respawned_this_level = true
	if AudioManager:
		AudioManager.play_second_wind()
	emit_signal("second_wind_activated")

func player_take_damage(amount: int = 1, reason: String = "Defeated on the ridge.") -> void:
	damage_taken_this_level += amount
	player_current_health = clampi(player_current_health - amount, 0, player_max_health)
	if AudioManager:
		AudioManager.play_player_hurt()
	emit_signal("health_changed", player_current_health, player_max_health)
	if player_current_health <= 0:
		is_level_active = false
		emit_signal("game_over", reason)

func enemy_defeated() -> void:
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	level_kills += 1
	total_kills_session += 1
	if AudioManager:
		AudioManager.play_enemy_die()
	emit_signal("enemy_count_changed", enemies_remaining, enemies_total)
	if enemies_remaining == 0:
		portal_is_open = true
		if AudioManager:
			AudioManager.play_portal_unlock()
		emit_signal("portal_unlocked")

func complete_level() -> void:
	is_level_active = false
	var lvl_id = current_level_idx + 1
	if not completed_levels.has(lvl_id):
		completed_levels.append(lvl_id)
	if lvl_id >= unlocked_level and lvl_id < total_levels:
		unlocked_level = lvl_id + 1

	# CHECK ACHIEVEMENTS
	if has_respawned_this_level:
		unlock_achievement("never_give_up")
	if damage_taken_this_level == 0:
		unlock_achievement("untouchable")
	if crystals_total_level > 0 and crystals_collected_level >= crystals_total_level:
		unlock_achievement("crystal_seeker")
	if lvl_id >= 6:
		unlock_achievement("high_altitude")

	save_progress()
	if AudioManager:
		AudioManager.play_portal_unlock()
	emit_signal("level_completed", level_time, level_kills, enemies_total, crystals_collected_level, crystals_total_level)
	get_tree().change_scene_to_file("res://scenes/ui/level_completed.tscn")

func boss_defeated() -> void:
	is_level_active = false
	total_kills_session += 1
	if not completed_levels.has(7):
		completed_levels.append(7)
	unlock_achievement("ultimate_comeback")
	save_progress()
	if AudioManager:
		AudioManager.play_victory()
	get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func unlock_achievement(ach_id: String) -> void:
	if not unlocked_achievements.has(ach_id) and ACHIEVEMENTS_DATA.has(ach_id):
		unlocked_achievements[ach_id] = true
		var data = ACHIEVEMENTS_DATA[ach_id]
		emit_signal("achievement_unlocked", ach_id, data["title"], data["desc"])
		save_progress()

func start_level(index: int) -> void:
	current_level_idx = index
	var level_scene_path = "res://scenes/levels/summit_%02d.tscn" % (index + 1)
	get_tree().change_scene_to_file(level_scene_path)

func restart_current_level() -> void:
	start_level(current_level_idx)

func next_level() -> void:
	if current_level_idx + 1 < total_levels:
		start_level(current_level_idx + 1)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

func unlock_all_levels() -> void:
	unlocked_level = 7
	save_progress()

func save_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progression", "unlocked_level", unlocked_level)
	cfg.set_value("progression", "completed_levels", completed_levels)
	cfg.set_value("progression", "achievements", unlocked_achievements)
	cfg.set_value("progression", "saved_crystals", saved_crystals)
	cfg.set_value("progression", "saved_open_world_crystals", saved_open_world_crystals)
	cfg.set_value("progression", "collected_crystal_uids", collected_crystal_uids)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_level = cfg.get_value("progression", "unlocked_level", 1)
		completed_levels = cfg.get_value("progression", "completed_levels", [])
		unlocked_achievements = cfg.get_value("progression", "achievements", {})
		saved_crystals = cfg.get_value("progression", "saved_crystals", {})
		saved_open_world_crystals = cfg.get_value("progression", "saved_open_world_crystals", {})
		collected_crystal_uids = cfg.get_value("progression", "collected_crystal_uids", {})
