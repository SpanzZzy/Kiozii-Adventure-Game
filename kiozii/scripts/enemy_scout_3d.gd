extends CharacterBody3D

# ridge scout controller (supports 2.5d and open-world 3d)
@export var is_open_world: bool = false
@export var max_health: int = 2
@export var speed: float = 3.8
@export var min_x: float = 0.0
@export var max_x: float = 10.0
@export var detection_range: float = 16.0
@export var patrol_radius: float = 12.0

var current_health: int
var dir: float = 1.0
var hit_flash: float = 0.0
var base_speed: float = 3.8
var home_pos: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var target_pos: Vector3 = Vector3.ZERO

@onready var visual_root: Node3D = $Visuals
@onready var health_bar: Node3D = $EnemyHealthBar3D

func _ready() -> void:
	add_to_group("enemies")
	apply_level_scaling()
	current_health = max_health
	home_pos = global_position
	target_pos = home_pos
	if health_bar:
		health_bar.set_health(current_health, max_health)

func apply_level_scaling() -> void:
	var lvl = GameManager.current_level_idx + 1
	if lvl <= 2:
		max_health = 2
		base_speed = 3.8
	elif lvl <= 4:
		max_health = 3
		base_speed = 4.6
	elif lvl <= 6:
		max_health = 4
		base_speed = 5.4
	speed = base_speed

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 30.0 * delta

	if is_open_world:
		process_3d_ai(delta)
	else:
		process_2d_ai(delta)

	move_and_slide()

	if hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.15, 1.15, 1.15)
	else:
		visual_root.scale = Vector3.ONE

	# player contact attack
	for i in range(get_slide_collision_count()):
		var coll = get_slide_collision(i)
		var collider = coll.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(1, dir, "Ambushed by a ridge scout!")

func process_3d_ai(delta: float) -> void:
	var player_node: Node3D = null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]

	if player_node:
		var dist = global_position.distance_to(player_node.global_position)
		if dist <= detection_range:
			var to_player = (player_node.global_position - global_position)
			to_player.y = 0.0
			if to_player.length_squared() > 1.0:
				var move_dir = to_player.normalized()
				velocity.x = move_dir.x * speed
				velocity.z = move_dir.z * speed
				visual_root.rotation.y = atan2(-move_dir.x, -move_dir.z)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			return

	# patrol wander when player not in detection range
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(2.0, 4.5)
		var angle = randf() * TAU
		var r = randf_range(2.0, patrol_radius)
		target_pos = home_pos + Vector3(cos(angle) * r, 0, sin(angle) * r)

	var to_target = (target_pos - global_position)
	to_target.y = 0.0
	if to_target.length_squared() > 1.2:
		var move_dir = to_target.normalized()
		velocity.x = move_dir.x * (speed * 0.6)
		velocity.z = move_dir.z * (speed * 0.6)
		visual_root.rotation.y = atan2(-move_dir.x, -move_dir.z)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func process_2d_ai(_delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0

	if global_position.x <= min_x:
		global_position.x = min_x
		dir = 1.0
	elif global_position.x >= max_x:
		global_position.x = max_x
		dir = -1.0

	velocity.x = dir * speed
	visual_root.rotation.y = 0.0 if dir > 0 else PI

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
