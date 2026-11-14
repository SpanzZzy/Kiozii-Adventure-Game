extends Area3D

@onready var core_mesh: CSGBox3D = $Visuals/Core
@onready var status_label: Label3D = $Visuals/StatusLabel

var is_unlocked: bool = false
var is_portal_entered: bool = false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	GameManager.connect("portal_unlocked", Callable(self, "_on_portal_unlocked"))
	update_state(GameManager.portal_is_open)

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	if is_unlocked and core_mesh and is_instance_valid(core_mesh):
		core_mesh.rotation.y = sin(Time.get_ticks_msec() * 0.005) * 0.25

func update_state(open: bool) -> void:
	is_unlocked = open
	if not is_inside_tree():
		return
	if is_unlocked:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.06, 0.72, 0.5, 0.85)
		mat.emission_enabled = true
		mat.emission = Color(0.06, 0.72, 0.5, 1.0)
		mat.emission_energy_multiplier = 2.0
		if core_mesh and is_instance_valid(core_mesh):
			core_mesh.material = mat
		if status_label and is_instance_valid(status_label):
			status_label.text = "SUMMIT PORTAL OPEN!"
			status_label.modulate = Color(0.2, 1.0, 0.5, 1.0)
	else:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.33, 0.41, 0.7)
		if core_mesh and is_instance_valid(core_mesh):
			core_mesh.material = mat
		if status_label and is_instance_valid(status_label):
			status_label.text = "PORTAL SEALED"
			status_label.modulate = Color(0.7, 0.7, 0.8, 0.8)

func _on_portal_unlocked() -> void:
	update_state(true)

func _on_body_entered(body: Node3D) -> void:
	if not is_inside_tree() or is_portal_entered:
		return
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	# in open world mode, open_world_mountain.gd handles victory screen transition
	if get_parent() and get_parent().name == "OpenWorldMountain":
		return
	if body.is_in_group("player") and is_unlocked:
		is_portal_entered = true
		set_deferred("monitoring", false)
		GameManager.complete_level()
