extends CharacterBody3D

# final boss overlord controller (supports 2.5d and open-world 3d)
signal boss_health_changed(current_health: int, max_health: int)

@export var is_open_world: bool = false
@export var max_health: int = 65
@export var arena_center_3d: Vector3 = Vector3(600.0, 142.0, 0.0)
@export var arena_radius_3d: float = 28.0

var current_health: int
var state_timer: float = 1.0
var attack_index: int = 0
var hit_flash: float = 0.0
var facing: float = -1.0
var is_dead: bool = false
var is_enraged: bool = false
var is_slam_plunging: bool = false
var contact_damage_cooldown: float = 0.0
var boss_move_vel: Vector3 = Vector3.ZERO
var strafe_dir: float = 1.0
var strafe_timer: float = 0.0

# 2.5d arena boundaries
const ARENA_MIN_X: float = 4.5
const ARENA_MAX_X: float = 41.5
const ARENA_FLOOR_Y: float = 0.0
const VOID_Y_THRESHOLD: float = -4.0

var spawn_pos: Vector3 = Vector3(34.0, 0.0, 0.0)
var bullet_scene = preload("res://scenes/weapons/enemy_bullet_3d.tscn")

@onready var visual_root: Node3D = $Visuals
@onready var muzzle_left: Marker3D = $Visuals/MuzzleLeft
@onready var muzzle_right: Marker3D = $Visuals/MuzzleRight
@onready var muzzle_chest: Marker3D = $Visuals.get_node_or_null("MuzzleChest")
var player_node: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	spawn_pos = global_position
	boss_health_changed.emit(current_health, max_health)
	GameManager.emit_signal("boss_health_changed", current_health, max_health)
	call_deferred("_emit_initial_health")

func _emit_initial_health() -> void:
	boss_health_changed.emit(current_health, max_health)
	GameManager.emit_signal("boss_health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead or not is_inside_tree():
		return

	# locate player reference
	if not player_node or not is_instance_valid(player_node) or not player_node.is_inside_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0].is_inside_tree():
			player_node = players[0]
		else:
			return

	# gravity and slam plunge physics
	if is_slam_plunging:
		if is_on_floor():
			on_ground_slam_impact()
		else:
			if velocity.y < 0.0:
				velocity.y -= 58.0 * delta
			else:
				velocity.y -= 44.0 * delta
	elif not is_on_floor():
		velocity.y -= 44.0 * delta
	else:
		# on floor movement - immunity to external knockback while preserving intentional movement
		velocity.x = boss_move_vel.x
		if is_open_world:
			velocity.z = boss_move_vel.z
		else:
			velocity.z = 0.0

	move_and_slide()

	if is_open_world:
		process_3d_boss(delta)
	else:
		process_2d_boss(delta)

	# body contact damage
	process_contact_damage(delta)

	# visual effects and enrage pulse
	process_visual_effects(delta)

	# attack cycle state machine
	state_timer -= delta
	if state_timer <= 0.0 and (is_on_floor() or not is_slam_plunging):
		if is_open_world:
			execute_boss_attack_3d()
		else:
			execute_boss_attack_2d()

func process_visual_effects(delta: float) -> void:
	if is_enraged:
		var enrage_pulse = 1.0 + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.12
		visual_root.scale = Vector3(enrage_pulse, enrage_pulse, enrage_pulse)
	elif hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.08, 1.08, 1.08)
	else:
		visual_root.scale = Vector3.ONE

func process_contact_damage(delta: float) -> void:
	if contact_damage_cooldown > 0.0:
		contact_damage_cooldown -= delta
	if not player_node or not is_instance_valid(player_node) or not player_node.is_inside_tree():
		return
	if contact_damage_cooldown <= 0.0:
		var p_pos = player_node.global_position
		var flat_dist = Vector2(p_pos.x - global_position.x, (p_pos.z - global_position.z) if is_open_world else 0.0).length()
		var dy = p_pos.y - global_position.y
		if flat_dist < 2.4 and dy >= -0.6 and dy <= 3.8:
			contact_damage_cooldown = 0.6
			var knock_dir = signf(p_pos.x - global_position.x)
			if knock_dir == 0.0:
				knock_dir = facing
			player_node.take_damage(1, knock_dir, "Trampled by the Summit Overlord!")

func process_2d_boss(delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0

	# void recovery
	if global_position.y < VOID_Y_THRESHOLD:
		global_position = spawn_pos
		velocity = Vector3.ZERO
		is_slam_plunging = false
		state_timer = 1.0

	# horizontal arena boundary clamp
	if global_position.x < ARENA_MIN_X:
		global_position.x = ARENA_MIN_X
		if velocity.x < 0.0:
			velocity.x = 0.0
	elif global_position.x > ARENA_MAX_X:
		global_position.x = ARENA_MAX_X
		if velocity.x > 0.0:
			velocity.x = 0.0

	if is_on_floor() and velocity.y == 0.0 and global_position.y < ARENA_FLOOR_Y:
		global_position.y = ARENA_FLOOR_Y

	# face player
	facing = -1.0 if player_node.global_position.x < global_position.x else 1.0
	visual_root.rotation.y = 0.0 if facing > 0 else PI

	# aggressive ground advance and positioning
	if not is_slam_plunging and is_on_floor():
		var dx = absf(player_node.global_position.x - global_position.x)
		var move_speed = 7.5 if not is_enraged else 11.0
		if dx > 10.0:
			boss_move_vel.x = facing * move_speed
		elif dx < 3.5:
			boss_move_vel.x = -facing * 4.5
		else:
			boss_move_vel.x = facing * 2.8

func process_3d_boss(delta: float) -> void:
	# arena boundary clamp
	var flat_offset = Vector2(global_position.x - arena_center_3d.x, global_position.z - arena_center_3d.z)
	if flat_offset.length() > arena_radius_3d:
		var clamped = flat_offset.normalized() * arena_radius_3d
		global_position.x = arena_center_3d.x + clamped.x
		global_position.z = arena_center_3d.z + clamped.y

	# void recovery
	if global_position.y < arena_center_3d.y - 12.0:
		global_position = spawn_pos
		velocity = Vector3.ZERO
		is_slam_plunging = false
		state_timer = 1.0

	# face player in full 3d
	var to_player = player_node.global_position - global_position
	visual_root.rotation.y = atan2(-to_player.x, -to_player.z)

	# aggressive stalking and circling
	if not is_slam_plunging and is_on_floor():
		var to_player_flat = Vector2(to_player.x, to_player.z)
		var dist = to_player_flat.length()
		var move_speed = 8.5 if not is_enraged else 13.0
		if dist > 9.0:
			var dir = to_player_flat.normalized()
			boss_move_vel = Vector3(dir.x, 0.0, dir.y) * move_speed
		elif dist < 4.0:
			var dir = -to_player_flat.normalized()
			boss_move_vel = Vector3(dir.x, 0.0, dir.y) * 5.0
		else:
			strafe_timer -= delta
			if strafe_timer <= 0.0:
				strafe_timer = randf_range(1.0, 2.2)
				strafe_dir = -strafe_dir
			var tangent = Vector2(-to_player_flat.y, to_player_flat.x).normalized() * strafe_dir
			boss_move_vel = Vector3(tangent.x, 0.0, tangent.y) * (move_speed * 0.75)

func on_ground_slam_impact() -> void:
	is_slam_plunging = false
	boss_move_vel = Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	AudioManager.play_boss_slam()

	# direct crater impact damage
	if player_node and is_instance_valid(player_node) and player_node.is_inside_tree():
		var p_pos = player_node.global_position
		var dist = global_position.distance_to(p_pos)
		if dist <= 5.2 and absf(p_pos.y - global_position.y) <= 3.0:
			var knock = signf(p_pos.x - global_position.x)
			if knock == 0.0:
				knock = facing
			player_node.take_damage(2, knock, "Crushed beneath the Overlord's meteor slam!")

	# spawn expanding ground shockwave ring
	var speed_mult = 1.35 if is_enraged else 1.0
	if is_open_world:
		var ring_count = 12 if is_enraged else 8
		for i in range(ring_count):
			var angle = i * (TAU / float(ring_count))
			var dir = Vector3(cos(angle), 0.0, sin(angle))
			spawn_shockwave_3d(dir * 18.0 * speed_mult)
	else:
		spawn_shockwave_2d(-22.0 * speed_mult)
		spawn_shockwave_2d(22.0 * speed_mult)

func execute_boss_attack_2d() -> void:
	attack_index = (attack_index + 1) % 3
	var speed_mult = 1.35 if is_enraged else 1.0
	var timer_mult = 0.55 if is_enraged else 0.85
	var p_target = player_node.global_position + Vector3(0.0, 0.85, 0.0)
	var spawn_pos_ref = get_spawn_pos_2d(1.25)
	var to_player_dir = (p_target - spawn_pos_ref).normalized()

	if attack_index == 0:
		# 5-way spread fan aimed directly at player height
		state_timer = 1.1 * timer_mult
		AudioManager.play_shoot()
		var base_angle = atan2(to_player_dir.y, to_player_dir.x)
		var angles = [-24.0, -12.0, 0.0, 12.0, 24.0]
		for deg in angles:
			var rad = base_angle + deg_to_rad(deg)
			var spd = 20.0 * speed_mult
			spawn_bullet_2d(cos(rad) * spd, sin(rad) * spd, 1.25)
	elif attack_index == 1:
		# meteor leap and ground slam
		state_timer = 1.5 * timer_mult
		velocity.y = 26.0
		var target_x = clampf(player_node.global_position.x, ARENA_MIN_X + 2.0, ARENA_MAX_X - 2.0)
		velocity.x = (target_x - global_position.x) * 1.5
		is_slam_plunging = true
		AudioManager.play_boss_slam()
	else:
		# rapid gatling laser burst (4 shots, 6 if enraged)
		state_timer = 1.2 * timer_mult
		var burst_count = 6 if is_enraged else 4
		for i in range(burst_count):
			get_tree().create_timer(i * 0.10).timeout.connect(func():
				if not is_dead and player_node and is_inside_tree():
					var cur_target = player_node.global_position + Vector3(0.0, 0.85, 0.0)
					var cur_spawn = get_spawn_pos_2d(1.4 if (i % 2 == 0) else 1.0)
					var cur_dir = (cur_target - cur_spawn).normalized()
					var spd = 24.0 * speed_mult
					AudioManager.play_shoot()
					spawn_bullet_2d(cur_dir.x * spd, cur_dir.y * spd, 1.4 if (i % 2 == 0) else 1.0)
			)

func execute_boss_attack_3d() -> void:
	attack_index = (attack_index + 1) % 3
	var speed_mult = 1.35 if is_enraged else 1.0
	var timer_mult = 0.55 if is_enraged else 0.85
	var p_target = player_node.global_position + Vector3(0.0, 0.85, 0.0)

	if attack_index == 0:
		# 5-way conical spread aimed directly at player height
		state_timer = 1.2 * timer_mult
		AudioManager.play_shoot()
		var spawn_pos_center = global_position + Vector3(0.0, 1.5, 0.0)
		var to_player_dir = (p_target - spawn_pos_center).normalized()
		var right_vec = to_player_dir.cross(Vector3.UP).normalized()
		var angles = [-22.0, -11.0, 0.0, 11.0, 22.0]
		for deg in angles:
			var rad = deg_to_rad(deg)
			var spread_dir = (to_player_dir * cos(rad) + right_vec * sin(rad)).normalized()
			spawn_bullet_3d(spread_dir * 22.0 * speed_mult, spawn_pos_center)
	elif attack_index == 1:
		# 3d meteor leap and ground slam
		state_timer = 1.7 * timer_mult
		velocity.y = 26.0
		var target_offset = player_node.global_position - global_position
		target_offset.y = 0.0
		var leap_dist = target_offset.length()
		var leap_speed = clampf(leap_dist * 1.6, 12.0, 26.0)
		var leap_vel = target_offset.normalized() * leap_speed
		velocity.x = leap_vel.x
		velocity.z = leap_vel.z
		is_slam_plunging = true
		AudioManager.play_boss_slam()
	else:
		# rapid alternating twin-cannon laser burst
		state_timer = 1.3 * timer_mult
		var burst_count = 6 if is_enraged else 4
		for i in range(burst_count):
			get_tree().create_timer(i * 0.10).timeout.connect(func():
				if not is_dead and player_node and is_inside_tree():
					var use_left = (i % 2 == 0)
					var m_pos = get_spawn_pos_3d("left" if use_left else "right")
					var cur_target = player_node.global_position + Vector3(0.0, 0.85, 0.0)
					var dir = (cur_target - m_pos).normalized()
					AudioManager.play_shoot()
					spawn_bullet_3d(dir * 26.0 * speed_mult, m_pos)
			)

func get_spawn_pos_2d(muzzle_offset_y: float = 1.25) -> Vector3:
	return Vector3(global_position.x + facing * 1.8, global_position.y + muzzle_offset_y, 0.0)

func spawn_bullet_2d(vx: float, vy: float, spawn_y_offset: float = 1.25) -> void:
	if bullet_scene:
		var pos = get_spawn_pos_2d(spawn_y_offset)
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = pos
		bullet.set_velocity_3d(Vector3(vx, vy, 0.0), false)

func spawn_shockwave_2d(vx: float) -> void:
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = Vector3(global_position.x, global_position.y + 0.35, 0.0)
	if bullet.has_method("set_ignore_terrain"):
		bullet.set_ignore_terrain(true)
	bullet.scale = Vector3(1.6, 0.7, 1.6)
	bullet.set_velocity_3d(Vector3(vx, 0.0, 0.0), false)

func get_spawn_pos_3d(muzzle_name: String = "left") -> Vector3:
	if muzzle_name == "left" and muzzle_left:
		return muzzle_left.global_position
	elif muzzle_name == "right" and muzzle_right:
		return muzzle_right.global_position
	elif muzzle_chest:
		return muzzle_chest.global_position
	return global_position + Vector3(0.0, 1.5, 0.0)

func spawn_bullet_3d(vel: Vector3, spawn_pos_override: Vector3 = Vector3.ZERO) -> void:
	if bullet_scene:
		var pos = spawn_pos_override if spawn_pos_override != Vector3.ZERO else get_spawn_pos_3d("left")
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = pos
		bullet.set_velocity_3d(vel, true)

func spawn_shockwave_3d(vel: Vector3) -> void:
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = Vector3(global_position.x, global_position.y + 0.35, global_position.z)
	if bullet.has_method("set_ignore_terrain"):
		bullet.set_ignore_terrain(true)
	bullet.scale = Vector3(1.6, 0.7, 1.6)
	bullet.set_velocity_3d(vel, true)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = maxi(current_health - amount, 0)
	hit_flash = 0.12
	AudioManager.play_enemy_hit()

	# enrage trigger under 50% health (<= 32 HP)
	if not is_enraged and current_health <= 32 and current_health > 0:
		is_enraged = true
		AudioManager.play_boss_slam()

	boss_health_changed.emit(current_health, max_health)
	GameManager.emit_signal("boss_health_changed", current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	GameManager.boss_defeated()
	queue_free()
