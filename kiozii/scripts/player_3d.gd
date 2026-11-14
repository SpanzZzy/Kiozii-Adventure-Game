extends CharacterBody3D

# PLAYER CONTROLLER PROPERTIES
@export var speed: float = 12.0
@export var accel: float = 95.0
@export var friction: float = 85.0
@export var jump_force: float = 24.5
@export var gravity: float = 54.0

var facing: float = 1.0
var shoot_cooldown: float = 0.0
var invuln_timer: float = 0.0
var coyote_timer: float = 0.0
var anim_timer: float = 0.0
var idle_timer: float = 0.0

var bullet_scene = preload("res://scenes/weapons/player_bullet_3d.tscn")

@onready var visual_root: Node3D = $Visuals
@onready var torso: Node3D = $Visuals/Torso
@onready var head: Node3D = $Visuals/Head
@onready var left_leg: Node3D = $Visuals/LeftLeg
@onready var right_leg: Node3D = $Visuals/RightLeg
@onready var scarf: Node3D = $Visuals/Scarf
@onready var muzzle: Marker3D = $Visuals/Muzzle
@onready var muzzle_flash: Node3D = $Visuals/MuzzleFlash

var spawn_position: Vector3 = Vector3(4, 4, 0)

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	muzzle_flash.visible = false

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	velocity.z = 0.0

	# TIMERS UPDATE
	if invuln_timer > 0.0:
		invuln_timer -= delta
		visual_root.visible = int(invuln_timer * 18.0) % 2 == 0
	else:
		visual_root.visible = true

	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	else:
		muzzle_flash.visible = false

	# GROUND AND COYOTE TIME
	if is_on_floor():
		coyote_timer = 0.12
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y -= gravity * delta
		if velocity.y < -34.0:
			velocity.y = -34.0

	# JUMP
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = jump_force
		coyote_timer = 0.0
		AudioManager.play_jump()

	# HORIZONTAL MOVEMENT
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = signf(dir)
		velocity.x += dir * accel * delta
		if absf(velocity.x) > speed:
			velocity.x = signf(velocity.x) * speed
		anim_timer += delta * 13.0
	else:
		var decel = friction * delta
		if absf(velocity.x) <= decel:
			velocity.x = 0.0
		else:
			velocity.x -= signf(velocity.x) * decel
		anim_timer = 0.0

	move_and_slide()

	# ROTATION TOWARDS FACING DIRECTION
	var target_rot_y = 0.0 if facing > 0 else PI
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, clampf(delta * 18.0, 0.0, 1.0))

	# IDLE AND WALK ANIMATIONS
	if is_on_floor():
		if absf(velocity.x) > 0.5:
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

	# SHOOTING
	if Input.is_action_pressed("shoot") and shoot_cooldown <= 0.0:
		shoot()

	# HAZARD FALL RESET
	if global_position.y < -7.0:
		global_position = spawn_position
		velocity = Vector3.ZERO
		take_damage(1, 0.0, "You fell into a deep mountain chasm!")

func shoot() -> void:
	shoot_cooldown = 0.21
	muzzle_flash.visible = true
	AudioManager.play_shoot()
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.set_direction(facing)
		get_parent().add_child(bullet)

func take_damage(amount: int = 1, knockback_dir: float = 0.0, reason: String = "Defeated on the ridge.") -> void:
	if invuln_timer > 0.0:
		return
	invuln_timer = 1.1
	if knockback_dir != 0.0:
		velocity.x = knockback_dir * 11.0
		velocity.y = 11.0
	GameManager.player_take_damage(amount, reason)
