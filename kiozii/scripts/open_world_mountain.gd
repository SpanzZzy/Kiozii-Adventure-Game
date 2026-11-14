extends Node3D

# open-world mountain master controller
@onready var player: CharacterBody3D = $Player3D
@onready var hud: CanvasLayer = $HUDOpenWorld3D
@onready var ambience = $LevelAmbience3D
@onready var victory_portal: Area3D = $VictoryPortal

const REGION_NAMES = {
	1: "Green Highlands",
	2: "Autumn Peaks",
	3: "Rocky Canyon",
	4: "Frozen Ridge",
	5: "Crystal Mountains",
	6: "Ember Summit",
	7: "The Final Summit"
}

var current_region: int = 1
var is_victory_triggered: bool = false
var is_boss_defeated: bool = false

func _ready() -> void:
	# initialize player in open-world 3d mode
	if player:
		player.is_open_world = true
		player.spawn_position = Vector3(0.0, 2.5, 0.0)
		GameManager.current_checkpoint_pos = player.spawn_position
		GameManager.has_custom_checkpoint = false
		
	GameManager.reset_for_level(0, false)
	GameManager.portal_is_open = false
	GameManager.set_current_region(1)
	
	if ambience:
		ambience.level_number = 1
		ambience.setup_theme(1)
		
	if AudioManager:
		AudioManager.play_level_ambience(1)
		
	if victory_portal:
		victory_portal.update_state(false)
		victory_portal.set_deferred("monitoring", false)
		victory_portal.connect("body_entered", Callable(self, "_on_victory_portal_entered"))

	var boss = get_boss()
	if boss:
		if boss.has_signal("boss_health_changed") and hud:
			if not boss.boss_health_changed.is_connected(hud._on_boss_health_changed):
				boss.boss_health_changed.connect(hud._on_boss_health_changed)
		if boss.has_signal("boss_defeated_in_world"):
			boss.boss_defeated_in_world.connect(Callable(self, "_on_boss_defeated"))

func _physics_process(_delta: float) -> void:
	if not is_inside_tree() or is_victory_triggered:
		return
	if not player or not player.is_inside_tree():
		return
		
	var detected_reg = get_region_at_position(player.global_position)
		
	if detected_reg != current_region:
		transition_to_region(detected_reg)

func get_region_at_position(pos: Vector3) -> int:
	var px = pos.x
	if px < 40.0:
		return 1
	elif px < 140.0:
		return 2
	elif px < 240.0:
		return 3
	elif px < 340.0:
		return 4
	elif px < 440.0:
		return 5
	elif px < 540.0:
		return 6
	else:
		return 7

func transition_to_region(new_region: int) -> void:
	current_region = new_region
	GameManager.set_current_region(new_region)
	
	if hud and hud.has_method("show_region_banner"):
		hud.show_region_banner(new_region)
		
	if ambience and ambience.has_method("setup_theme"):
		ambience.setup_theme(new_region)
		
	if AudioManager and AudioManager.has_method("play_level_ambience"):
		AudioManager.play_level_ambience(new_region)

func get_all_crystals() -> Array:
	var crystals: Array = []
	for reg_idx in range(1, 8):
		var reg_node = get_node_or_null("Region0%d" % reg_idx if reg_idx < 10 else "Region%d" % reg_idx)
		if not reg_node:
			# search by region name prefix
			for child in get_children():
				if child.name.begins_with("Region0%d" % reg_idx):
					reg_node = child
					break
		if reg_node:
			for c in reg_node.get_children():
				if c.is_in_group("resolve_crystals") or c.name.begins_with("Crystal_"):
					crystals.append(c)
	return crystals

func get_all_checkpoints() -> Array:
	var shrines: Array = []
	for child in get_children():
		if child.name.begins_with("Region0"):
			for c in child.get_children():
				if c.name.begins_with("Altar"):
					shrines.append(c)
	return shrines

func get_all_enemies() -> Array:
	var enemies: Array = []
	for child in get_children():
		if child.name.begins_with("Region0"):
			for c in child.get_children():
				if c.is_in_group("enemies") or c.name.begins_with("Scout_") or c.name.begins_with("Sniper_") or c.name.begins_with("Golem_"):
					enemies.append(c)
	return enemies

func get_boss() -> Node:
	var reg7 = get_node_or_null("Region07_Summit")
	if reg7:
		return reg7.get_node_or_null("BossOverlord3D")
	return null

func _on_boss_defeated() -> void:
	if is_boss_defeated:
		return
	is_boss_defeated = true
	GameManager.portal_is_open = true
	GameManager.emit_signal("portal_unlocked")

	# dissolve runic barrier blocking the summit gate
	var barrier = get_node_or_null("Region07_Summit/BossGateBarrier")
	if barrier:
		var col = barrier.get_node_or_null("CollisionShape3D")
		if col:
			col.set_deferred("disabled", true)
		var forcefield = barrier.get_node_or_null("Forcefield")
		if forcefield:
			var tw = create_tween()
			tw.tween_property(forcefield, "scale", Vector3(0.01, 0.01, 0.01), 1.0)
			tw.tween_callback(func(): forcefield.visible = false)
		var gate_label = barrier.get_node_or_null("GateLabel")
		if gate_label:
			gate_label.text = "★ SUMMIT GATE UNSEALED ★"
			gate_label.modulate = Color(0.2, 1.0, 0.5, 1.0)

	# activate victory portal
	if victory_portal:
		victory_portal.update_state(true)
		victory_portal.set_deferred("monitoring", true)

	if AudioManager:
		AudioManager.play_portal_unlock()

	if hud and hud.has_method("show_toast"):
		hud.show_toast("★ SUMMIT OVERLORD DEFEATED! SUMMIT GATE UNSEALED! ★", Color(1.0, 0.85, 0.2, 1.0))

func respawn_player_at_shrine() -> void:
	var target_spawn = GameManager.get_checkpoint_position() if GameManager.has_active_checkpoint() else player.spawn_position
	player.global_position = target_spawn + Vector3(0.0, 1.2, 0.0)
	player.velocity = Vector3.ZERO
	GameManager.player_current_health = GameManager.player_max_health
	GameManager.is_level_active = true
	GameManager.emit_signal("health_changed", GameManager.player_current_health, GameManager.player_max_health)
	player.apply_second_wind()
	if AudioManager:
		AudioManager.play_second_wind()
	if hud and hud.has_method("show_toast"):
		hud.show_toast("BOUNCED BACK AT ACTIVE SHRINE! HEALTH RESTORED!", Color(0.2, 0.95, 0.55, 1.0))

func _on_victory_portal_entered(body: Node3D) -> void:
	if not is_inside_tree() or is_victory_triggered:
		return
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	if not is_boss_defeated:
		if hud and hud.has_method("show_toast"):
			hud.show_toast("THE SUMMIT GATE IS SEALED! DEFEAT THE OVERLORD FIRST!", Color(1.0, 0.3, 0.3, 1.0))
		return
	if body.is_in_group("player"):
		is_victory_triggered = true
		if victory_portal and is_instance_valid(victory_portal) and victory_portal.is_inside_tree():
			victory_portal.set_deferred("monitoring", false)
		if AudioManager:
			AudioManager.play_victory()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.unlock_achievement("ultimate_comeback")
		GameManager.save_progress()
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/victory_screen.tscn")
