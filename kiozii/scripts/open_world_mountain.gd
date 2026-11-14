extends Node3D

# OPEN-WORLD MOUNTAIN MASTER CONTROLLER
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

func _ready() -> void:
	# INITIALIZE PLAYER IN OPEN-WORLD 3D MODE
	if player:
		player.is_open_world = true
		player.spawn_position = Vector3(0.0, 2.5, 0.0)
		GameManager.current_checkpoint_pos = player.spawn_position
		GameManager.has_custom_checkpoint = false
		
	GameManager.reset_for_level(0, false)
	GameManager.set_current_region(1)
	
	if ambience:
		ambience.level_number = 1
		ambience.setup_theme(1)
		
	if AudioManager:
		AudioManager.play_level_ambience(1)
		
	if victory_portal:
		victory_portal.connect("body_entered", Callable(self, "_on_victory_portal_entered"))

func _physics_process(_delta: float) -> void:
	if not player:
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
			# SEARCH BY REGION NAME PREFIX
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

func _on_victory_portal_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if AudioManager:
			AudioManager.play_victory()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")
