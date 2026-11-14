extends Area3D

@export var speed: float = 26.0
@export var damage: int = 1
var direction: float = 1.0
var lifetime: float = 1.15

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func set_direction(dir: float) -> void:
	direction = dir

func _physics_process(delta: float) -> void:
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

