extends Node3D

# level-specific ambient environment controller
@export var level_number: int = 1

@onready var particles: CPUParticles3D = $AmbientParticles

var particle_mat: StandardMaterial3D

func _ready() -> void:
	if particles and particles.mesh and particles.mesh.material:
		particle_mat = particles.mesh.material.duplicate()
		particles.mesh.material = particle_mat
	elif particles:
		particle_mat = StandardMaterial3D.new()
		particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		particle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var quad = QuadMesh.new()
		quad.size = Vector2(0.2, 0.2)
		quad.material = particle_mat
		particles.mesh = quad
		
	setup_theme(level_number)
	apply_quality_preset(SettingsManager.graphics_preset)
	
	if SettingsManager.has_signal("graphics_preset_changed"):
		SettingsManager.connect("graphics_preset_changed", Callable(self, "apply_quality_preset"))
		
	if AudioManager:
		AudioManager.play_level_ambience(level_number)

func apply_quality_preset(preset_idx: int) -> void:
	if not particles:
		return
	if preset_idx == 0: # LOW (DEFAULT)
		particles.amount = 16
	elif preset_idx == 1: # MEDIUM
		particles.amount = 36
	else: # HIGH
		particles.amount = 64

func setup_theme(lvl: int) -> void:
	if not particles or not particle_mat:
		return
		
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(24.0, 9.0, 4.0)
	particles.local_coords = false
	particles.lifetime = 5.0
	
	match lvl:
		1: # SUMMIT 1 - GREEN HIGHLANDS (GENTLE WIND, DRIFTING LEAVES)
			particle_mat.albedo_color = Color(0.42, 0.72, 0.28, 0.75)
			particles.gravity = Vector3(1.2, -1.2, 0.0)
			particles.initial_velocity_min = 0.8
			particles.initial_velocity_max = 1.8
		2: # SUMMIT 2 - AUTUMN PEAKS (FALLING ORANGE & BROWN LEAVES)
			particle_mat.albedo_color = Color(0.85, 0.45, 0.15, 0.85)
			particles.gravity = Vector3(0.9, -1.6, 0.0)
			particles.initial_velocity_min = 0.6
			particles.initial_velocity_max = 1.5
		3: # SUMMIT 3 - ROCKY CANYON (DRIFTING DUST & CANYON WIND)
			particle_mat.albedo_color = Color(0.78, 0.70, 0.55, 0.45)
			particles.gravity = Vector3(2.6, -0.4, 0.0)
			particles.initial_velocity_min = 1.8
			particles.initial_velocity_max = 3.5
		4: # SUMMIT 4 - FROZEN RIDGE (GENTLE SNOWFALL & COLD MOUNTAIN WIND)
			particle_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.85)
			particles.gravity = Vector3(0.5, -1.8, 0.0)
			particles.initial_velocity_min = 0.5
			particles.initial_velocity_max = 1.4
		5: # SUMMIT 5 - CRYSTAL MOUNTAINS (CRYSTAL ILLUMINATION & FLOATING SPARKLES)
			particle_mat.albedo_color = Color(0.65, 0.88, 1.0, 0.85)
			particle_mat.emission_enabled = true
			particle_mat.emission = Color(0.5, 0.8, 1.0, 1.0)
			particle_mat.emission_energy_multiplier = 1.6
			particles.gravity = Vector3(0.2, 0.3, 0.0)
			particles.initial_velocity_min = 0.4
			particles.initial_velocity_max = 1.2
		6: # SUMMIT 6 - EMBER SUMMIT (FLOATING EMBERS & VOLCANIC AMBIENCE)
			particle_mat.albedo_color = Color(1.0, 0.48, 0.1, 0.9)
			particle_mat.emission_enabled = true
			particle_mat.emission = Color(1.0, 0.35, 0.0, 1.0)
			particle_mat.emission_energy_multiplier = 2.2
			particles.gravity = Vector3(0.8, 1.6, 0.0)
			particles.initial_velocity_min = 0.8
			particles.initial_velocity_max = 2.0
		7: # SUMMIT 7 - THE FINAL SUMMIT (STRONGER WIND & DRIFTING CLOUDS)
			particle_mat.albedo_color = Color(0.88, 0.92, 0.98, 0.35)
			particles.gravity = Vector3(3.8, -0.2, 0.0)
			particles.initial_velocity_min = 2.5
			particles.initial_velocity_max = 4.8

func _physics_process(_delta: float) -> void:
	# track active camera to immerse viewport
	var cam = get_viewport().get_camera_3d()
	if cam:
		global_position.x = cam.global_position.x
		global_position.y = cam.global_position.y
		global_position.z = 0.0
