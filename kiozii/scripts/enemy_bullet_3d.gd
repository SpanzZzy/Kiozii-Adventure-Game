extends Area3D

# ENEMY PROJECTILE CONTROLLER
@export var speed: float = 14.0
@export var damage: int = 1
var velocity: Vector3 = Vector3.ZERO
var lifetime: float = 2.6
var is_3d: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func set_velocity_3d(vel: Vector3, full_3d: bool = false) -> void:
	velocity = vel
	is_3d = full_3d

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	if not is_3d:
		global_position.z = 0.0
	rotation.z += delta * 8.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var knock_dir = signf(velocity.x)
		body.take_damage(damage, knock_dir, "Struck by an enemy energy blast!")
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()
