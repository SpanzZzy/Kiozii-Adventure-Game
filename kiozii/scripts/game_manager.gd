extends Node

signal health_changed(new_health, max_health)
signal enemy_count_changed(remaining, total)
signal boss_health_changed(current_hp, max_hp)
signal portal_unlocked
signal level_completed(clear_time, kills, total)
signal game_over(reason)

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	
	emit_signal("health_changed", player_current_health, player_max_health)
	emit_signal("enemy_count_changed", enemies_remaining, enemies_total)
	if portal_is_open:
		emit_signal("portal_unlocked")

func player_take_damage(amount: int = 1, reason: String = "Defeated on the ridge.") -> void:
	player_current_health = clampi(player_current_health - amount, 0, player_max_health)
	AudioManager.play_player_hurt()
	emit_signal("health_changed", player_current_health, player_max_health)
	if player_current_health <= 0:
		is_level_active = false
		emit_signal("game_over", reason)

func enemy_defeated() -> void:
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	level_kills += 1
	total_kills_session += 1
	AudioManager.play_enemy_die()
	emit_signal("enemy_count_changed", enemies_remaining, enemies_total)
	if enemies_remaining == 0:
		portal_is_open = true
		AudioManager.play_portal_unlock()
		emit_signal("portal_unlocked")

func complete_level() -> void:
	is_level_active = false
	var lvl_id = current_level_idx + 1
	if not completed_levels.has(lvl_id):
		completed_levels.append(lvl_id)
	if lvl_id >= unlocked_level and lvl_id < total_levels:
		unlocked_level = lvl_id + 1
	
	AudioManager.play_portal_unlock()
	emit_signal("level_completed", level_time, level_kills, enemies_total)
	get_tree().change_scene_to_file("res://scenes/ui/level_completed.tscn")

func boss_defeated() -> void:
	is_level_active = false
	total_kills_session += 1
	if not completed_levels.has(7):
		completed_levels.append(7)
	AudioManager.play_victory()
	get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")

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
