extends CharacterBody3D

@export var max_health: int = 65
var current_health: int

var state_timer: float = 1.5
var attack_index: int = 0
var hit_flash: float = 0.0
var facing: float = -1.0
var is_dead: bool = false

var bullet_scene = preload("res://scenes/weapons/enemy_bullet_3d.tscn")
@onready var visual_root: Node3D = $Visuals
@onready var muzzle_left: Marker3D = $Visuals/MuzzleLeft
@onready var muzzle_right: Marker3D = $Visuals/MuzzleRight
var player_node: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	GameManager.emit_signal("boss_health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	global_position.z = 0.0
	velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= 44.0 * delta
	else:
		velocity.x = 0.0

	move_and_slide()

	if is_on_floor() and velocity.y == 0.0 and global_position.y <= 0.1:
		global_position.y = 0.0

	if hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.06, 1.06, 1.06)
	else:
		visual_root.scale = Vector3.ONE

	if not player_node:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
		return

	facing = -1.0 if player_node.global_position.x < global_position.x else 1.0
	visual_root.rotation.y = 0.0 if facing > 0 else PI

	state_timer -= delta
	if state_timer <= 0.0 and is_on_floor():
		execute_boss_attack()

func execute_boss_attack() -> void:
	attack_index = (attack_index + 1) % 3
	if attack_index == 0:
		state_timer = 2.0
		AudioManager.play_shoot()
		for angle_deg in [-14.0, 0.0, 14.0]:
			spawn_bullet(facing * 14.5 * cos(deg_to_rad(angle_deg)), 14.5 * sin(deg_to_rad(angle_deg)))
	elif attack_index == 1:
		state_timer = 2.4
		velocity.y = 23.0
		var target_x = clampf(player_node.global_position.x, 4.0, 42.0)
		velocity.x = (target_x - global_position.x) * 1.05
		AudioManager.play_boss_slam()
		spawn_bullet(-13.0, 0.0)
		spawn_bullet(13.0, 0.0)
	else:
		state_timer = 1.9
		AudioManager.play_shoot()
		spawn_bullet(facing * 18.5, 0.0)
		get_tree().create_timer(0.24).timeout.connect(func():
			if not is_dead:
				AudioManager.play_shoot()
				spawn_bullet(facing * 18.5, 0.0)
		)

func spawn_bullet(vx: float, vy: float) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle_left.global_position
		bullet.set_velocity_3d(Vector3(vx, vy, 0))
		get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = maxi(current_health - amount, 0)
	hit_flash = 0.1
	AudioManager.play_enemy_hit()
	GameManager.emit_signal("boss_health_changed", current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	GameManager.boss_defeated()
	queue_free()
