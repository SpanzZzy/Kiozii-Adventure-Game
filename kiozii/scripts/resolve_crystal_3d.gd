extends Area3D

# resolve crystal collectible (kaju katli sweet shape)
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
	# generate canonical unique identifier if empty
	if crystal_unique_id.is_empty():
		var reg = maxi(1, region_id)
		crystal_unique_id = "summit_%02d_crystal_%02d" % [reg, crystal_id + 1]

	collision_layer = 0
	collision_mask = 2 # PLAYER COLLISION MASK
	monitoring = true
	monitorable = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	start_y = global_position.y
	
	# check if previously collected across save data
	if GameManager and GameManager.is_crystal_unique_collected(crystal_unique_id, region_id, crystal_id):
		collected = true
		queue_free()

func _physics_process(delta: float) -> void:
	if collected or not is_inside_tree():
		return
	# smooth slow rotation
	rotation.y += delta * 1.6
	# gentle floating bob
	global_position.y = start_y + sin(Time.get_ticks_msec() * 0.003) * 0.18

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	# atomic guard against multiple triggers
	if collected:
		return
	collected = true

	# immediately disable detection and collision deferred
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# register unique id and update gamemanager before emitting notifications
	if GameManager:
		GameManager.register_crystal_collected(crystal_unique_id, region_id, crystal_id)

	# play collection tween and queue free
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
