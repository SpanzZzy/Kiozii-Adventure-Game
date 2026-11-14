extends CharacterBody3D

# ARMORED RIDGE GOLEM CONTROLLER
@export var max_health: int = 5
@export var speed: float = 4.5
@export var min_x: float = 0.0
@export var max_x: float = 12.0

var current_health: int
var dir: float = 1.0
var hit_flash: float = 0.0
var base_speed: float = 4.5

@onready var visual_root: Node3D = $Visuals

func _ready() -> void:
	add_to_group("enemies")
	apply_level_scaling()
	current_health = max_health

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
	global_position.z = 0.0
	velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= 35.0 * delta

	if global_position.x <= min_x:
		global_position.x = min_x
		dir = 1.0
	elif global_position.x >= max_x:
		global_position.x = max_x
		dir = -1.0

	velocity.x = dir * speed
	move_and_slide()

	visual_root.rotation.y = 0.0 if dir > 0 else PI

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

func take_damage(amount: int) -> void:
	current_health -= amount
	hit_flash = 0.12
	AudioManager.play_enemy_hit()
	if current_health <= 0:
		die()

func die() -> void:
	GameManager.enemy_defeated()
	queue_free()
