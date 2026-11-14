extends Area3D

# player projectile controller
@export var speed: float = 26.0
@export var damage: int = 1
var direction: float = 1.0
var lifetime: float = 1.15
var velocity_3d: Vector3 = Vector3.ZERO
var is_3d: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func set_direction(dir: float) -> void:
	direction = dir
	is_3d = false

func set_velocity_3d(vel: Vector3) -> void:
	velocity_3d = vel
	is_3d = true

func _physics_process(delta: float) -> void:
	if is_3d:
		global_position += velocity_3d * delta
	else:
		global_position.x += direction * speed * delta
		global_position.z = 0.0
		
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
