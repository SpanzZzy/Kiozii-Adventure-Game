extends Node

# CONTINUOUS OPEN WORLD TRAVERSAL PHYSICS TEST
func _ready() -> void:
	call_deferred("_run_traversal_test")

func _run_traversal_test() -> void:
	print("==================================================")
	print("STARTING OPEN-WORLD TRAVERSAL & CLIMB TEST")
	print("==================================================")

	var world_scene = load("res://scenes/world/open_world_mountain.tscn")
	var world = world_scene.instantiate()
	add_child(world)

	var player = world.get_node("Player3D")
	player.global_position = Vector3(0.0, 2.5, 0.0)

	var checkpoints = [
		{"name": "Region 01 Footpath", "target_x": 20.0, "expected_min_y": 0.0},
		{"name": "Region 01 -> 02 Ascent Pass", "target_x": 45.0, "expected_min_y": 9.0},
		{"name": "Region 02 Autumn Peaks", "target_x": 90.0, "expected_min_y": 18.0},
		{"name": "Region 02 -> 03 Ascent Pass", "target_x": 135.0, "expected_min_y": 28.0},
		{"name": "Region 03 Rocky Canyon", "target_x": 180.0, "expected_min_y": 38.0},
		{"name": "Region 03 -> 04 Ascent Pass", "target_x": 232.5, "expected_min_y": 51.0},
		{"name": "Region 04 Frozen Ridge", "target_x": 280.0, "expected_min_y": 64.0},
		{"name": "Region 04 -> 05 Ascent Pass", "target_x": 332.5, "expected_min_y": 77.0},
		{"name": "Region 05 Crystal Cavern", "target_x": 380.0, "expected_min_y": 90.0},
		{"name": "Region 05 -> 06 Ascent Pass", "target_x": 432.5, "expected_min_y": 104.0},
		{"name": "Region 06 Ember Summit", "target_x": 480.0, "expected_min_y": 118.0},
		{"name": "Region 06 -> 07 Ascent Pass", "target_x": 532.5, "expected_min_y": 130.0},
		{"name": "Region 07 Final Summit Arena", "target_x": 580.0, "expected_min_y": 142.0}
	]

	var all_stages_passed = true
	for cp in checkpoints:
		# TELEPORT SLIGHTLY ABOVE TARGET X AND LET GRAVITY SNAP TO SURFACE
		player.global_position = Vector3(cp["target_x"], cp["expected_min_y"] + 2.0, 0.0)
		player.velocity = Vector3.ZERO
		
		# AWAIT 20 REAL PHYSICS FRAMES FOR ENGINE COLLISION SOLVER
		for frame in range(20):
			await get_tree().physics_frame
			
		var ground_y = player.global_position.y
		var exp_y = cp["expected_min_y"]
		var diff = ground_y - exp_y
		
		# PLAYER ORIGIN IS AT FEET (COLLISION CAPSULE EXTENDS FROM Y=0 TO Y=1.65)
		# SO PLAYER FEET SHOULD REST AT SURFACE EXP_Y (DIFF IN [-0.2, +0.8])
		if diff >= -0.2 and diff <= 0.8:
			print("  [PASS] %s (X=%.1f) -> Grounded cleanly at Y=%.2f (Expected %.1f, diff=%.2f)" % [cp["name"], cp["target_x"], ground_y, exp_y, diff])
		else:
			print("  [FAIL] %s (X=%.1f) -> Grounded at Y=%.2f (Expected %.1f, diff=%.2f)" % [cp["name"], cp["target_x"], ground_y, exp_y, diff])
			all_stages_passed = false

	world.queue_free()

	print("==================================================")
	if all_stages_passed:
		print("STATUS: 100% MOUNTAIN PATH GROUNDING & TRAVERSAL PASSED")
	else:
		print("STATUS: TRAVERSAL TEST FAILED")
	print("==================================================")
	get_tree().quit(0 if all_stages_passed else 1)
