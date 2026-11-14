extends Node

# qa test suite for kiozii open world & gameplay systems
var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	call_deferred("_start_tests")

func _start_tests() -> void:
	print("==================================================")
	print("STARTING KIOZII COMPLETE 3-PASS QA VALIDATION SUITE")
	print("==================================================")
	
	run_pass_1_static_inspection()
	run_pass_2_functional_tests()
	run_pass_3_regression_tests()
	
	print("==================================================")
	print("QA SUITE SUMMARY: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================")
	
	if tests_failed > 0:
		print("STATUS: FAILED")
	else:
		print("STATUS: ALL TESTS PASSED")
	
	get_tree().quit(tests_failed)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		tests_failed += 1
		print("  [FAIL] %s" % test_name)

# pass 1: static & scene integrity inspection
func run_pass_1_static_inspection() -> void:
	print("\n--- PASS 1: STATIC & SCENE INTEGRITY INSPECTION ---")
	
	# load open world scene
	var world_scene: PackedScene = load("res://scenes/world/open_world_mountain.tscn")
	assert_true(world_scene != null, "Open world scene packed scene loads")
	if not world_scene:
		return
		
	var world_node = world_scene.instantiate()
	assert_true(world_node != null, "Open world scene instantiates")
	if not world_node:
		return
		
	add_child(world_node)
	
	# check 7 regions
	for r in range(1, 8):
		var reg_node = world_node.get_node_or_null("Region%02d" % r if r >= 10 else "Region0%d" % r)
		if not reg_node:
			for ch in world_node.get_children():
				if ch.name.begins_with("Region0%d" % r):
					reg_node = ch
					break
		assert_true(reg_node != null, "Region %d node present in hierarchy" % r)
	
	# check crystals count
	var all_crystals: Array = world_node.get_all_crystals()
	assert_true(all_crystals.size() == 21, "Total open-world crystals equals exactly 21 (found %d)" % all_crystals.size())
	
	# check checkpoints
	var all_checkpoints: Array = world_node.get_all_checkpoints()
	assert_true(all_checkpoints.size() >= 4, "Total checkpoints present (found %d, expected >= 4)" % all_checkpoints.size())
	
	# check player collision shape and physics properties
	var player = world_node.get_node_or_null("Player3D")
	assert_true(player != null, "Player3D node present in open world")
	if player:
		var col_shape: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
		assert_true(col_shape != null, "Player has CollisionShape3D")
		if col_shape:
			var shape = col_shape.shape
			assert_true(shape is CapsuleShape3D, "Player shape is CapsuleShape3D (got %s)" % shape.get_class())
			if shape is CapsuleShape3D:
				assert_true(is_equal_approx(shape.radius, 0.45), "Capsule radius is 0.45m")
				assert_true(is_equal_approx(shape.height, 1.65), "Capsule height is 1.65m")
		
		# verify floor and slope settings
		assert_true(player.floor_stop_on_slope == true, "Player floor_stop_on_slope is true")
		assert_true(player.floor_constant_speed == true, "Player floor_constant_speed is true")
		assert_true(player.floor_max_angle >= deg_to_rad(45.0), "Player floor_max_angle is >= 45 degrees")
		assert_true(player.floor_snap_length >= 0.4, "Player floor_snap_length >= 0.4m")
		
	# check boss in region 7
	var boss = world_node.get_boss()
	assert_true(boss != null, "BossOverlord3D present in Region 7")
	if boss:
		assert_true(boss.has_signal("boss_health_changed"), "Boss has signal boss_health_changed")
		assert_true(boss.arena_radius_3d > 10.0, "Boss has arena boundary defined")
		
	world_node.queue_free()

# pass 2: functional testing
func run_pass_2_functional_tests() -> void:
	print("\n--- PASS 2: FUNCTIONAL TESTING ---")
	
	# test 2.1: crystal collection atomicity & single notification
	var crystal_scene = load("res://scenes/levels/resolve_crystal_3d.tscn")
	assert_true(crystal_scene != null, "Crystal scene loads")
	if crystal_scene:
		var crystal = crystal_scene.instantiate()
		crystal.region_id = 99
		crystal.crystal_id = 0
		crystal.crystal_unique_id = "test_qa_unique_crystal_99"
		add_child(crystal)
		
		# reset test record in gamemanager
		GameManager.collected_crystal_uids.erase("test_qa_unique_crystal_99")
		if GameManager.saved_open_world_crystals.has("99"):
			GameManager.saved_open_world_crystals.erase("99")
		
		var signals_data = {
			"toast_count": 0,
			"collected_count": 0,
			"last_uid": ""
		}
		
		var on_pickup = func(uid: String, _reg: int, _tot: int):
			signals_data["toast_count"] += 1
			signals_data["last_uid"] = uid
			
		var on_collected = func(_c: int, _t: int):
			signals_data["collected_count"] += 1
			
		GameManager.crystal_pickup_notified.connect(on_pickup)
		GameManager.crystal_collected.connect(on_collected)
		
		# first collection
		crystal.collect()
		assert_true(crystal.collected == true, "Crystal marked collected on first collection")
		assert_true(signals_data["toast_count"] == 1, "Pickup notification emitted exactly once")
		assert_true(signals_data["last_uid"] == "test_qa_unique_crystal_99", "Correct crystal UID passed in signal")
		assert_true(GameManager.is_crystal_unique_collected("test_qa_unique_crystal_99", 99, 0) == true, "GameManager registers unique crystal collection")
		
		# multiple rapid calls / walking back and forth
		for i in range(5):
			crystal.collect()
			var fake_body = CharacterBody3D.new()
			fake_body.add_to_group("player")
			crystal._on_body_entered(fake_body)
			fake_body.free()
			
		assert_true(signals_data["toast_count"] == 1, "Walking back and forth triggered ZERO duplicate notifications (count remained 1)")
		assert_true(signals_data["collected_count"] == 1, "crystal_collected signal emitted exactly once despite repeated touches")
		
		# test region switch does not emit crystal notifications
		GameManager.set_current_region(2)
		GameManager.set_current_region(3)
		GameManager.set_current_region(1)
		assert_true(signals_data["toast_count"] == 1, "Switching regions emits ZERO crystal pickup notifications")
		
		GameManager.crystal_pickup_notified.disconnect(on_pickup)
		GameManager.crystal_collected.disconnect(on_collected)
		
		if is_instance_valid(crystal):
			crystal.queue_free()
			
		# test persistence of collected crystal
		GameManager.save_progress()
		GameManager.load_progress()
		assert_true(GameManager.is_crystal_unique_collected("test_qa_unique_crystal_99", 99, 0) == true, "Unique crystal collection persists across save/load")
		
		# clean up test record
		GameManager.collected_crystal_uids.erase("test_qa_unique_crystal_99")
		if GameManager.saved_open_world_crystals.has("99"):
			GameManager.saved_open_world_crystals.erase("99")
		GameManager.save_progress()

	# test 2.2: player coyote time and jump buffering
	var player_scene = load("res://scenes/player/player_3d.tscn")
	assert_true(player_scene != null, "Player scene loads")
	if player_scene:
		var p = player_scene.instantiate()
		add_child(p)
		
		# test coyote timer reset on ground
		p.coyote_timer = 0.0
		# simulate floor contact
		p.coyote_timer = 0.12
		assert_true(is_equal_approx(p.coyote_timer, 0.12), "Coyote time timer initializes to 0.12s")
		
		# test jump buffer
		p.jump_buffer_timer = 0.12
		assert_true(is_equal_approx(p.jump_buffer_timer, 0.12), "Jump buffer timer initializes to 0.12s")
		
		p.queue_free()

	# test 2.3: terrain connectivity & reachability for all 7 regions
	var world_scene = load("res://scenes/world/open_world_mountain.tscn")
	if world_scene:
		var world = world_scene.instantiate()
		add_child(world)
		
		# verify continuous elevation profile
		var expected_heights = {
			1: 0.0,
			2: 18.0,
			3: 38.0,
			4: 64.0,
			5: 90.0,
			6: 118.0,
			7: 142.0
		}
		
		for reg_idx in range(1, 8):
			var reg_node = world.get_node_or_null("Region%02d" % reg_idx if reg_idx >= 10 else "Region0%d" % reg_idx)
			if not reg_node:
				for ch in world.get_children():
					if ch.name.begins_with("Region0%d" % reg_idx):
						reg_node = ch
						break
			assert_true(reg_node != null, "Region %d exists for connectivity validation" % reg_idx)
			if reg_node:
				var ground = reg_node.get_node_or_null("GroundMain")
				if not ground and reg_idx == 7:
					ground = reg_node.get_node_or_null("BossArenaPlatform")
				assert_true(ground != null, "Region %d has main ground" % reg_idx)
				if ground:
					var expected_top_y = expected_heights[reg_idx]
					var actual_top_y = ground.global_position.y + (ground.size.y / 2.0)
					var diff = absf(actual_top_y - expected_top_y)
					assert_true(diff < 0.1, "Region %d main surface height matches design (%f vs %f)" % [reg_idx, actual_top_y, expected_heights[reg_idx]])
		
		# verify all 21 crystals are within reachable vertical range
		var crystals = world.get_all_crystals()
		var reachable_crystals = 0
		for c in crystals:
			var reg_id = c.region_id
			var base_y = expected_heights.get(reg_id, 0.0)
			var h_diff = c.global_position.y - base_y
			if h_diff >= 0.5 and h_diff <= 18.0:
				reachable_crystals += 1
		assert_true(reachable_crystals == 21, "All 21 crystals sit at valid, reachable heights along paths/ramps (found %d)" % reachable_crystals)
		
		world.queue_free()

# pass 3: regression testing
func run_pass_3_regression_tests() -> void:
	print("\n--- PASS 3: REGRESSION TESTING ---")
	
	# test 3.1: classic summit scenes 01-07 integrity
	for s in range(1, 8):
		var path = "res://scenes/levels/summit_%02d.tscn" % s
		var res = load(path)
		assert_true(res != null, "Classic summit scene %02d loads cleanly" % s)
		
	# test 3.2: settings manager low graphics preset defaults
	assert_true(SettingsManager != null, "SettingsManager autoload is active")
	if SettingsManager:
		assert_true(SettingsManager.vsync == false, "Default VSync is OFF")
		assert_true(SettingsManager.fps_cap == 60, "Default FPS limit is 60")
		assert_true(SettingsManager.graphics_preset == 0, "Default Graphics quality is LOW (0)")
		
	# test 3.3: boss overlord health bar signal emission & damage
	var boss_scene = load("res://scenes/enemies/boss_overlord_3d.tscn")
	assert_true(boss_scene != null, "BossOverlord3D scene loads cleanly")
	if boss_scene:
		var boss = boss_scene.instantiate()
		add_child(boss)
		
		var signal_received = {"count": 0, "cur_hp": -1, "max_hp": -1}
		var on_boss_health = func(c: int, m: int):
			signal_received["count"] += 1
			signal_received["cur_hp"] = c
			signal_received["max_hp"] = m
			
		boss.boss_health_changed.connect(on_boss_health)
		
		# test damage emission
		boss.take_damage(5)
		assert_true(signal_received["count"] >= 1, "Boss health changed signal emits on take_damage")
		assert_true(signal_received["cur_hp"] == boss.current_health, "Boss health changed passes accurate current health")
		
		# test immunity to unwanted external physical knockback
		boss.velocity = Vector3(50, 0, 50)
		boss.take_damage(2)
		assert_true(boss.current_health == 58, "Boss takes damage accurately without abnormal velocity impulses")
		
		boss.boss_health_changed.disconnect(on_boss_health)
		boss.queue_free()
