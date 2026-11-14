extends Area3D

# RESOLVE CRYSTAL COLLECTIBLE
@export var crystal_id: int = 0
var is_collected: bool = false
var start_y: float = 0.0

@onready var mesh: MeshInstance3D = $Visuals/CrystalMesh
@onready var light: OmniLight3D = $Visuals/OmniLight3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player CharacterBody3D is on layer 2
	monitoring = true
	monitorable = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	start_y = global_position.y
	
	# AUTO-CHECK IF ALREADY COLLECTED
	if GameManager.is_crystal_collected(crystal_id):
		queue_free()

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
	if is_collected:
		return
	is_collected = true
	monitoring = false
	GameManager.on_crystal_collected(crystal_id)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
