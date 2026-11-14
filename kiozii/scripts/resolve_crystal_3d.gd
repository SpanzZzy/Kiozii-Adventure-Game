extends Area3D

# RESOLVE CRYSTAL COLLECTIBLE (KAJU KATLI SWEET SHAPE)
@export var region_id: int = 0
@export var crystal_id: int = 0
var is_collected: bool = false
var start_y: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var light: OmniLight3D = $Visuals/OmniLight3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # PLAYER COLLISION MASK
	monitoring = true
	monitorable = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	start_y = global_position.y
	
	# CHECK IF PREVIOUSLY COLLECTED FOR THIS REGION / LEVEL
	var already_got = false
	if region_id > 0:
		already_got = GameManager.is_region_crystal_collected(region_id, crystal_id)
	else:
		already_got = GameManager.is_crystal_collected(crystal_id)
		
	if already_got:
		queue_free()

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	# SMOOTH SLOW ROTATION
	rotation.y += delta * 1.6
	# GENTLE FLOATING BOB
	global_position.y = start_y + sin(Time.get_ticks_msec() * 0.003) * 0.18

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
	
	if region_id > 0:
		GameManager.on_region_crystal_collected(region_id, crystal_id)
	else:
		GameManager.on_crystal_collected(crystal_id)
		
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
