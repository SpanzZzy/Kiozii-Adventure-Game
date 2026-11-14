extends Area3D

# RESOLVE CRYSTAL COLLECTIBLE
var is_collected: bool = false
var start_y: float = 0.0

@onready var mesh: MeshInstance3D = $Visuals/CrystalMesh

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	start_y = global_position.y
	GameManager.crystals_total_level += 1

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	rotation.y += delta * 2.8
	global_position.y = start_y + sin(Time.get_ticks_msec() * 0.005) * 0.25

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	is_collected = true
	GameManager.on_crystal_collected()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.15)
	tween.tween_callback(queue_free)
