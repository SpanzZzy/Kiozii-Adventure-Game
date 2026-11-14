extends Area3D

# RESOLVE CRYSTAL COLLECTIBLE (KAJU KATLI SWEET SHAPE)
@export var region_id: int = 0
@export var crystal_id: int = 0
@export var crystal_unique_id: String = ""

var collected: bool = false
var is_collected: bool:
	get: return collected
	set(v): collected = v

var start_y: float = 0.0

@onready var visuals: Node3D = $Visuals
@onready var light: OmniLight3D = $Visuals/OmniLight3D
@onready var collision_shape: CollisionShape3D = $Collision

func _ready() -> void:
	# GENERATE CANONICAL UNIQUE IDENTIFIER IF EMPTY
	if crystal_unique_id.is_empty():
		var reg = maxi(1, region_id)
		crystal_unique_id = "summit_%02d_crystal_%02d" % [reg, crystal_id + 1]

	collision_layer = 0
	collision_mask = 2 # PLAYER COLLISION MASK
	monitoring = true
	monitorable = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	start_y = global_position.y
	
	# CHECK IF PREVIOUSLY COLLECTED ACROSS SAVE DATA
	if GameManager and GameManager.is_crystal_unique_collected(crystal_unique_id, region_id, crystal_id):
		collected = true
		queue_free()

func _physics_process(delta: float) -> void:
	if collected:
		return
	# SMOOTH SLOW ROTATION
	rotation.y += delta * 1.6
	# GENTLE FLOATING BOB
	global_position.y = start_y + sin(Time.get_ticks_msec() * 0.003) * 0.18

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	# ATOMIC GUARD AGAINST MULTIPLE TRIGGERS
	if collected:
		return
	collected = true

	# IMMEDIATELY DISABLE DETECTION AND COLLISION DEFERRED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# REGISTER UNIQUE ID AND UPDATE GAMEMANAGER BEFORE EMITTING NOTIFICATIONS
	if GameManager:
		GameManager.register_crystal_collected(crystal_unique_id, region_id, crystal_id)

	# PLAY COLLECTION TWEEN AND QUEUE FREE
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
