extends CharacterBody3D

# player controller properties
@export var is_open_world: bool = false
@export var speed: float = 12.0
@export var accel: float = 95.0
@export var friction: float = 85.0
@export var jump_force: float = 24.5
@export var gravity: float = 54.0
@export var mouse_sensitivity: float = 0.003
@export var sprint_multiplier: float = 1.55

var facing: float = 1.0
var shoot_cooldown: float = 0.0
var invuln_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var anim_timer: float = 0.0
var idle_timer: float = 0.0

# third-person camera rotation
var cam_yaw: float = 0.0
var cam_pitch: float = -0.15

# second wind bounce back properties
var second_wind_timer: float = 0.0
const SECOND_WIND_DURATION: float = 2.4
const SECOND_WIND_SPEED_BOOST: float = 3.5

var bullet_scene = preload("res://scenes/weapons/player_bullet_3d.tscn")

@onready var visual_root: Node3D = $Visuals
@onready var torso: Node3D = $Visuals/Torso
@onready var head: Node3D = $Visuals/Head
@onready var left_leg: Node3D = $Visuals/LeftLeg
@onready var right_leg: Node3D = $Visuals/RightLeg
@onready var scarf: Node3D = $Visuals/Scarf
@onready var muzzle: Marker3D = $Visuals/Muzzle
@onready var muzzle_flash: Node3D = $Visuals/MuzzleFlash

@onready var camera_arm: SpringArm3D = get_node_or_null("CameraArm")
@onready var tp_camera: Camera3D = get_node_or_null("CameraArm/ThirdPersonCamera")

var spawn_position: Vector3 = Vector3(4, 4, 0)

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	muzzle_flash.visible = false

	# configure floor & slope physics
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.45
	
	# configure camera mode
	if is_open_world:
		if tp_camera:
			tp_camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if tp_camera:
			tp_camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_open_world:
		return
		
	# mouse look for third-person camera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw -= event.relative.x * mouse_sensitivity
		cam_pitch = clampf(cam_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-60.0), deg_to_rad(45.0))
		if camera_arm:
			camera_arm.rotation.y = cam_yaw
			camera_arm.rotation.x = cam_pitch
			
	# mouse capture toggle
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	# timers update
	if invuln_timer > 0.0:
		invuln_timer -= delta
		visual_root.visible = int(invuln_timer * 18.0) % 2 == 0
	else:
		visual_root.visible = true

	if second_wind_timer > 0.0:
		second_wind_timer -= delta
		var pulse = 1.0 + absf(sin(second_wind_timer * 9.0)) * 0.12
		visual_root.scale = Vector3(pulse, pulse, pulse)
	else:
		visual_root.scale = Vector3.ONE

	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	else:
		muzzle_flash.visible = false

	# jump input buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.12
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	# ground detection & coyote time
	if is_on_floor():
		coyote_timer = 0.12
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y -= gravity * delta
		if velocity.y < -36.0:
			velocity.y = -36.0

	# execute buffered jump with coyote time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		AudioManager.play_jump()

	# branch: full 3d open world vs 2.5d classic summits
	if is_open_world:
		process_3d_movement(delta)
	else:
		process_2d_movement(delta)

	move_and_slide()

	# animations
	process_character_animations(delta)

	# shooting
	if Input.is_action_pressed("shoot") and shoot_cooldown <= 0.0:
		if is_open_world:
			shoot_3d()
		else:
			shoot_2d()

	# hazard fall reset - bounce back checkpoint recovery
	var fall_threshold = -15.0 if is_open_world else -7.0
	if global_position.y < fall_threshold:
		var target_spawn = GameManager.current_checkpoint_pos if GameManager.has_custom_checkpoint else spawn_position
		global_position = target_spawn
		velocity = Vector3.ZERO
		take_damage(1, 0.0, "You fell into a deep mountain chasm!")
		apply_second_wind()

func process_3d_movement(delta: float) -> void:
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_forward", "move_backward")
	var is_sprint = Input.is_action_pressed("sprint")
	var cur_speed = (speed * sprint_multiplier if is_sprint else speed) + (SECOND_WIND_SPEED_BOOST if second_wind_timer > 0.0 else 0.0)
	
	# camera-relative movement vectors
	var arm_rot_y = camera_arm.rotation.y if camera_arm else 0.0
	var forward = -Vector3(sin(arm_rot_y), 0, cos(arm_rot_y))
	var right = Vector3(cos(arm_rot_y), 0, -sin(arm_rot_y))
	var move_dir = (forward * -input_z + right * input_x).normalized()
	
	if move_dir.length_squared() > 0.01:
		velocity.x = move_dir.x * cur_speed
		velocity.z = move_dir.z * cur_speed
		var target_angle = atan2(-move_dir.x, -move_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, clampf(delta * 14.0, 0.0, 1.0))
		anim_timer += delta * (18.0 if is_sprint else 12.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		anim_timer = 0.0

func process_2d_movement(delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0
	
	var cur_speed = speed + (SECOND_WIND_SPEED_BOOST if second_wind_timer > 0.0 else 0.0)
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = signf(dir)
		velocity.x += dir * accel * delta
		if absf(velocity.x) > cur_speed:
			velocity.x = signf(velocity.x) * cur_speed
		anim_timer += delta * (15.0 if second_wind_timer > 0.0 else 13.0)
	else:
		var decel = friction * delta
		if absf(velocity.x) <= decel:
			velocity.x = 0.0
		else:
			velocity.x -= signf(velocity.x) * decel
		anim_timer = 0.0
		
	var target_rot_y = 0.0 if facing > 0 else PI
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, clampf(delta * 18.0, 0.0, 1.0))

func process_character_animations(delta: float) -> void:
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		if h_speed > 0.5:
			var swing = sin(anim_timer) * 0.65
			left_leg.rotation.z = swing
			right_leg.rotation.z = -swing
			torso.position.y = 0.85 + absf(sin(anim_timer * 2.0)) * 0.05
			head.position.y = 1.4 + absf(sin(anim_timer * 2.0)) * 0.05
		else:
			idle_timer += delta * 4.0
			var breathe = sin(idle_timer) * 0.03
			left_leg.rotation.z = 0.0
			right_leg.rotation.z = 0.0
			torso.position.y = 0.85 + breathe
			head.position.y = 1.4 + breathe * 1.5
	else:
		left_leg.rotation.z = 0.3
		right_leg.rotation.z = -0.3

	scarf.rotation.z = sin(Time.get_ticks_msec() * 0.01) * 0.3

func apply_second_wind() -> void:
	invuln_timer = 1.8
	second_wind_timer = SECOND_WIND_DURATION
	GameManager.trigger_second_wind()

func shoot_2d() -> void:
	shoot_cooldown = 0.21
	muzzle_flash.visible = true
	AudioManager.play_shoot()
	if bullet_scene:
		var spawn_pos = muzzle.global_position
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = spawn_pos
		bullet.set_direction(facing)

func shoot_3d() -> void:
	shoot_cooldown = 0.20
	muzzle_flash.visible = true
	AudioManager.play_shoot()
	if not bullet_scene:
		return
		
	var spawn_pos = muzzle.global_position
	var bullet = bullet_scene.instantiate()
	
	# raycast target from active camera
	var target_point: Vector3
	if tp_camera:
		var ray_origin = tp_camera.global_position
		var ray_dir = -tp_camera.global_transform.basis.z
		target_point = ray_origin + ray_dir * 70.0
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, target_point, 1 | 4)
		query.exclude = [self]
		var hit = space.intersect_ray(query)
		if hit:
			target_point = hit.position
	else:
		target_point = spawn_pos + -visual_root.global_transform.basis.z * 50.0
		
	var bullet_vel = (target_point - spawn_pos).normalized() * 34.0
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	bullet.set_velocity_3d(bullet_vel)

func take_damage(amount: int = 1, knockback_dir: float = 0.0, reason: String = "Defeated on the ridge.") -> void:
	if invuln_timer > 0.0:
		return
	invuln_timer = 1.1
	if knockback_dir != 0.0 and not is_open_world:
		velocity.x = knockback_dir * 11.0
		velocity.y = 11.0
	GameManager.player_take_damage(amount, reason)
