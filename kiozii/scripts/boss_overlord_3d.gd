extends CharacterBody3D

# FINAL BOSS OVERLORD CONTROLLER (SUPPORTS 2.5D AND OPEN-WORLD 3D)
@export var is_open_world: bool = false
@export var max_health: int = 65
@export var arena_center_3d: Vector3 = Vector3(600.0, 150.0, 0.0)
@export var arena_radius_3d: float = 28.0

var current_health: int
var state_timer: float = 1.5
var attack_index: int = 0
var hit_flash: float = 0.0
var facing: float = -1.0
var is_dead: bool = false
var is_enraged: bool = false

# 2.5D ARENA SAFETY BOUNDARIES
const ARENA_MIN_X: float = 4.5
const ARENA_MAX_X: float = 41.5
const ARENA_FLOOR_Y: float = 0.0
const VOID_Y_THRESHOLD: float = -4.0

var spawn_pos: Vector3 = Vector3(34.0, 0.0, 0.0)
var bullet_scene = preload("res://scenes/weapons/enemy_bullet_3d.tscn")

@onready var visual_root: Node3D = $Visuals
@onready var muzzle_left: Marker3D = $Visuals/MuzzleLeft
@onready var muzzle_right: Marker3D = $Visuals/MuzzleRight
var player_node: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	spawn_pos = global_position
	GameManager.emit_signal("boss_health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# IMMUNITY TO EXTERNAL PHYSICAL KNOCKBACK
	if is_on_floor():
		velocity.x = 0.0
		if is_open_world:
			velocity.z = 0.0
	else:
		velocity.y -= 44.0 * delta

	move_and_slide()

	if is_open_world:
		process_3d_boss(delta)
	else:
		process_2d_boss(delta)

	# ENRAGE CHECK AND VISUAL FEEDBACK
	if is_enraged:
		var enrage_pulse = 1.0 + absf(sin(Time.get_ticks_msec() * 0.008)) * 0.08
		visual_root.scale = Vector3(enrage_pulse, enrage_pulse, enrage_pulse)
	elif hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.06, 1.06, 1.06)
	else:
		visual_root.scale = Vector3.ONE

	# PLAYER TRACKING
	if not player_node:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
		return

	if is_open_world:
		var to_player = player_node.global_position - global_position
		visual_root.rotation.y = atan2(-to_player.x, -to_player.z)
	else:
		facing = -1.0 if player_node.global_position.x < global_position.x else 1.0
		visual_root.rotation.y = 0.0 if facing > 0 else PI

	# STATE MACHINE ATTACK TIMER
	state_timer -= delta
	if state_timer <= 0.0 and is_on_floor():
		if is_open_world:
			execute_boss_attack_3d()
		else:
			execute_boss_attack_2d()

func process_3d_boss(_delta: float) -> void:
	# VOID RECOVERY PRESERVING HEALTH
	if global_position.y < arena_center_3d.y - 12.0:
		global_position = spawn_pos
		velocity = Vector3.ZERO
		state_timer = 1.5

	# CIRCULAR ARENA HORIZONTAL CLAMP
	var flat_offset = Vector2(global_position.x - arena_center_3d.x, global_position.z - arena_center_3d.z)
	if flat_offset.length() > arena_radius_3d:
		var clamped = flat_offset.normalized() * arena_radius_3d
		global_position.x = arena_center_3d.x + clamped.x
		global_position.z = arena_center_3d.z + clamped.y

func process_2d_boss(_delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0

	# VOID RECOVERY SAFETY
	if global_position.y < VOID_Y_THRESHOLD:
		global_position = spawn_pos
		velocity = Vector3.ZERO
		state_timer = 1.5

	# ARENA HORIZONTAL CLAMP
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

func execute_boss_attack_2d() -> void:
	attack_index = (attack_index + 1) % 3
	var speed_mult = 1.2 if is_enraged else 1.0
	var timer_mult = 0.75 if is_enraged else 1.0

	if attack_index == 0:
		state_timer = 2.0 * timer_mult
		AudioManager.play_shoot()
		for angle_deg in [-14.0, 0.0, 14.0]:
			spawn_bullet_2d(facing * 14.5 * speed_mult * cos(deg_to_rad(angle_deg)), 14.5 * speed_mult * sin(deg_to_rad(angle_deg)))
	elif attack_index == 1:
		state_timer = 2.4 * timer_mult
		velocity.y = 23.0
		var target_x = clampf(player_node.global_position.x, ARENA_MIN_X + 2.0, ARENA_MAX_X - 2.0)
		velocity.x = clampf((target_x - global_position.x) * 1.05, -16.0, 16.0)
		AudioManager.play_boss_slam()
		spawn_bullet_2d(-13.0 * speed_mult, 0.0)
		spawn_bullet_2d(13.0 * speed_mult, 0.0)
	else:
		state_timer = 1.9 * timer_mult
		AudioManager.play_shoot()
		spawn_bullet_2d(facing * 18.5 * speed_mult, 0.0)
		get_tree().create_timer(0.24).timeout.connect(func():
			if not is_dead:
				AudioManager.play_shoot()
				spawn_bullet_2d(facing * 18.5 * speed_mult, 0.0)
		)

func execute_boss_attack_3d() -> void:
	attack_index = (attack_index + 1) % 3
	var speed_mult = 1.25 if is_enraged else 1.0
	var timer_mult = 0.75 if is_enraged else 1.0
	var to_player = (player_node.global_position + Vector3(0, 0.8, 0) - muzzle_left.global_position).normalized()

	if attack_index == 0:
		state_timer = 2.2 * timer_mult
		AudioManager.play_shoot()
		# TRI-SHOT SPREAD IN 3D
		var base_yaw = visual_root.rotation.y
		for deg in [-18.0, 0.0, 18.0]:
			var dir_3d = Vector3(-sin(base_yaw + deg_to_rad(deg)), to_player.y * 0.4, -cos(base_yaw + deg_to_rad(deg))).normalized()
			spawn_bullet_3d(dir_3d * 16.0 * speed_mult)
	elif attack_index == 1:
		state_timer = 2.6 * timer_mult
		velocity.y = 22.0
		var target_offset = player_node.global_position - global_position
		target_offset.y = 0.0
		var leap_vel = target_offset.normalized() * clampf(target_offset.length() * 1.2, 8.0, 18.0)
		velocity.x = leap_vel.x
		velocity.z = leap_vel.z
		AudioManager.play_boss_slam()
		# GROUND SHOCKWAVE SPREAD
		for i in range(4):
			var a = i * (PI * 0.5)
			spawn_bullet_3d(Vector3(cos(a), 0, sin(a)) * 13.0 * speed_mult)
	else:
		state_timer = 2.0 * timer_mult
		AudioManager.play_shoot()
		spawn_bullet_3d(to_player * 20.0 * speed_mult)
		get_tree().create_timer(0.25).timeout.connect(func():
			if not is_dead and player_node:
				var to_p2 = (player_node.global_position + Vector3(0, 0.8, 0) - muzzle_right.global_position).normalized()
				AudioManager.play_shoot()
				spawn_bullet_3d(to_p2 * 20.0 * speed_mult)
		)

func spawn_bullet_2d(vx: float, vy: float) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle_left.global_position
		bullet.set_velocity_3d(Vector3(vx, vy, 0), false)
		get_parent().add_child(bullet)

func spawn_bullet_3d(vel: Vector3) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle_left.global_position
		bullet.set_velocity_3d(vel, true)
		get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = maxi(current_health - amount, 0)
	hit_flash = 0.1
	AudioManager.play_enemy_hit()

	# ENRAGE TRIGGER UNDER 25% (<= 16 HP)
	if not is_enraged and current_health <= 16 and current_health > 0:
		is_enraged = true
		AudioManager.play_boss_slam()

	GameManager.emit_signal("boss_health_changed", current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	GameManager.boss_defeated()
	queue_free()
