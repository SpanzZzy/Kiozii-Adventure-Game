extends CharacterBody3D

# ARMORED RIDGE GOLEM CONTROLLER (SUPPORTS 2.5D AND OPEN-WORLD 3D)
@export var is_open_world: bool = false
@export var max_health: int = 5
@export var speed: float = 4.5
@export var min_x: float = 0.0
@export var max_x: float = 12.0
@export var detection_range: float = 18.0

var current_health: int
var dir: float = 1.0
var hit_flash: float = 0.0
var base_speed: float = 4.5
var home_pos: Vector3 = Vector3.ZERO
var charge_cooldown: float = 0.0

@onready var visual_root: Node3D = $Visuals
@onready var health_bar: Node3D = $EnemyHealthBar3D

func _ready() -> void:
	add_to_group("enemies")
	apply_level_scaling()
	current_health = max_health
	home_pos = global_position
	if health_bar:
		health_bar.set_health(current_health, max_health)

func apply_level_scaling() -> void:
	var lvl = GameManager.current_level_idx + 1
	if lvl <= 2:
		max_health = 5
		base_speed = 4.5
	elif lvl <= 4:
		max_health = 6
		base_speed = 5.2
	elif lvl <= 6:
		max_health = 7
		base_speed = 5.8
	speed = base_speed

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 35.0 * delta

	if is_open_world:
		process_3d_golem(delta)
	else:
		process_2d_golem(delta)

	move_and_slide()

	if hit_flash > 0.0:
		hit_flash -= delta
		visual_root.scale = Vector3(1.15, 1.15, 1.15)
	else:
		visual_root.scale = Vector3.ONE

	for i in range(get_slide_collision_count()):
		var coll = get_slide_collision(i)
		var collider = coll.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(1, dir, "Crushed by an armored ridge golem!")

func process_3d_golem(_delta: float) -> void:
	var player_node: Node3D = null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]

	if player_node:
		var dist = global_position.distance_to(player_node.global_position)
		if dist <= detection_range:
			var to_player = (player_node.global_position - global_position)
			to_player.y = 0.0
			if to_player.length_squared() > 1.4:
				var move_dir = to_player.normalized()
				velocity.x = move_dir.x * speed
				velocity.z = move_dir.z * speed
				visual_root.rotation.y = atan2(-move_dir.x, -move_dir.z)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			return

	velocity.x = move_toward(velocity.x, 0.0, 10.0 * _delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * _delta)

func process_2d_golem(_delta: float) -> void:
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
