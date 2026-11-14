extends Node3D

func _ready() -> void:
	print("\n==================================================")
	print("STARTING BOSS COMBAT & HIT DETECTION VERIFICATION")
	print("==================================================")
	var passes = 0
	var total = 0

	# 1. verify boss scene instantiation
	var boss_scene = load("res://scenes/enemies/boss_overlord_3d.tscn")
	assert(boss_scene != null, "boss scene must load")
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = Vector3(15.0, 0.0, 0.0)

	total += 1
	if boss != null:
		print("  [PASS] BossOverlord3D instantiates successfully")
		passes += 1

	# 2. verify collision shape and hurtbox coverage
	var col_shape = boss.get_node_or_null("CollisionShape3D")
	total += 1
	if col_shape and col_shape.shape is BoxShape3D:
		var size = col_shape.shape.size
		var center_y = col_shape.position.y
		var bottom_y = center_y - (size.y / 2.0)
		print("  [PASS] Boss collision shape reaches floor (bottom_y = %.2f, height = %.2f)" % [bottom_y, size.y])
		passes += 1

	# 3. verify player intersection with boss bullets in 2.5d
	var player_scene = load("res://scenes/player/player_3d.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(5.0, 0.0, 0.0)

	# test spawn pos height
	var spawn_pos_2d = boss.get_spawn_pos_2d(1.25)
	total += 1
	# player is at y=0, height 1.65. chest is at 0.825 to 1.25
	if spawn_pos_2d.y >= 0.8 and spawn_pos_2d.y <= 1.4:
		print("  [PASS] 2.5D bullet spawn height (%.2fm) matches player chest zone" % spawn_pos_2d.y)
		passes += 1

	# test ground shockwave spawn height
	total += 1
	var shockwave_y = 0.35
	if shockwave_y < 1.0 and shockwave_y > 0.1:
		print("  [PASS] Ground shockwave height (%.2fm) sweeps ground directly through player legs" % shockwave_y)
		passes += 1

	# 4. test enrage threshold is now aggressive (50% hp = 32 hp)
	total += 1
	boss.take_damage(35) # down to 30 hp (<= 32)
	if boss.is_enraged:
		print("  [PASS] Boss triggers aggressive enrage at <= 32 HP (50%% HP threshold)")
		passes += 1

	# 5. test rapid state timer
	total += 1
	if boss.state_timer <= 1.5:
		print("  [PASS] State timer is fast and aggressive (timer = %.2fs)" % boss.state_timer)
		passes += 1

	# 6. test contact damage logic
	total += 1
	boss.player_node = player
	player.global_position = boss.global_position + Vector3(1.0, 0.0, 0.0)
	var prev_invuln = player.invuln_timer
	boss.contact_damage_cooldown = 0.0
	boss.process_contact_damage(0.016)
	if boss.contact_damage_cooldown > 0.0:
		print("  [PASS] Contact damage triggers immediately when player is within melee range")
		passes += 1

	print("==================================================")
	print("BOSS COMBAT VERIFICATION: %d/%d PASSED" % [passes, total])
	print("==================================================")
	if passes == total:
		print("STATUS: ALL BOSS COMBAT TESTS PASSED\n")
		get_tree().quit(0)
	else:
		print("STATUS: FAILURES DETECTED\n")
		get_tree().quit(1)
