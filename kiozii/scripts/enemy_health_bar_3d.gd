extends Node3D

# ENEMY FLOATING 3D HEALTH BAR

@onready var fill_mesh: MeshInstance3D = $FillPivot/Fill
@onready var fill_pivot: Node3D = $FillPivot

var fill_mat: StandardMaterial3D
var current_ratio: float = 1.0

func _ready() -> void:
	# DUPLICATE MATERIAL FOR UNIQUE INSTANCE PER ENEMY
	if fill_mesh and fill_mesh.material_override:
		fill_mat = fill_mesh.material_override.duplicate()
		fill_mesh.material_override = fill_mat
	else:
		fill_mat = StandardMaterial3D.new()
		fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fill_mat.albedo_color = Color(0.2, 0.88, 0.38, 1.0)
		fill_mat.render_priority = 2
		if fill_mesh:
			fill_mesh.material_override = fill_mat

func _process(_delta: float) -> void:
	# ALWAYS FACE ACTIVE CAMERA
	var cam = get_viewport().get_camera_3d()
	if cam:
		global_transform.basis = cam.global_transform.basis

func set_health(current: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var clamped_hp = clampi(current, 0, max_hp)
	var target_ratio = clampf(float(clamped_hp) / float(max_hp), 0.0, 1.0)
	current_ratio = target_ratio
	
	# UPDATE FILL SCALE
	if fill_pivot:
		fill_pivot.scale.x = target_ratio
		
	# UPDATE HEALTH COLOR BASED ON THRESHOLDS
	if fill_mat:
		if target_ratio > 0.60:
			fill_mat.albedo_color = Color(0.2, 0.88, 0.38, 1.0) # GREEN (HIGH)
		elif target_ratio > 0.25:
			fill_mat.albedo_color = Color(0.96, 0.82, 0.18, 1.0) # YELLOW (MODERATE)
		else:
			fill_mat.albedo_color = Color(0.95, 0.22, 0.25, 1.0) # RED (CRITICAL)
