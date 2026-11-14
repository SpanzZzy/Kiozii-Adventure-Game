extends CharacterBody3D

# RIDGE SNIPER CONTROLLER
@export var max_health: int = 3
@export var attack_range: float = 24.0
@export var fire_interval: float = 2.1
@export var bullet_speed: float = 12.0

var current_health: int
var shoot_timer: float = 1.3
var hit_flash: float = 0.0

var bullet_scene = preload("res://scenes/weapons/enemy_bullet_3d.tscn")
@onready var visual_root: Node3D = $Visuals
@onready var muzzle: Marker3D = $Visuals/Muzzle
@onready var health_bar: Node3D = $EnemyHealthBar3D
var player_node: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	apply_level_scaling()
	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

func apply_level_scaling() -> void:
	var lvl = GameManager.current_level_idx + 1
	if lvl <= 2:
		max_health = 3
		fire_interval = 2.1
		bullet_speed = 12.0
	elif lvl <= 4:
		max_health = 4
		fire_interval = 1.7
		bullet_speed = 14.5
	elif lvl <= 6:
		max_health = 5
		fire_interval = 1.35
		bullet_speed = 17.0

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= 30.0 * delta
	move_and_slide()

	if hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.15, 1.15, 1.15)
	else:
		visual_root.scale = Vector3.ONE

	if not player_node:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
		return

	var dist_x = absf(player_node.global_position.x - global_position.x)
	var dir_to_player = signf(player_node.global_position.x - global_position.x)
	visual_root.rotation.y = 0.0 if dir_to_player > 0 else PI

	if dist_x <= attack_range:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = fire_interval
			fire_at_player(dir_to_player)

func fire_at_player(dir: float) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.set_velocity_3d(Vector3(dir * bullet_speed, 0, 0))
		AudioManager.play_shoot()
		get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	hit_flash = 0.12
	AudioManager.play_enemy_hit()
	if health_bar:
		health_bar.set_health(current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	GameManager.enemy_defeated()
	queue_free()
