extends Area3D

# mountain checkpoint altar
@export var checkpoint_name: String = "Highland Altar"
var is_activated: bool = false

@onready var flame_mesh: MeshInstance3D = $Visuals/Flame
@onready var light: OmniLight3D = $Visuals/OmniLight3D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if flame_mesh:
		flame_mesh.scale = Vector3(0.5, 0.5, 0.5)
	if light:
		light.light_energy = 0.5

func _physics_process(delta: float) -> void:
	if is_activated and flame_mesh:
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.2
		flame_mesh.scale = Vector3(pulse, pulse * 1.3, pulse)

func _on_body_entered(body: Node3D) -> void:
	if is_activated:
		return
	if body.is_in_group("player"):
		activate_checkpoint()

func activate_checkpoint() -> void:
	is_activated = true
	if flame_mesh:
		flame_mesh.scale = Vector3(1.2, 1.6, 1.2)
	if light:
		light.light_energy = 2.5
	var respawn_pos = Vector3(global_position.x, global_position.y + 1.2, global_position.z)
	GameManager.set_checkpoint(respawn_pos, checkpoint_name)
	# restore player health upon resting at a shrine
	GameManager.player_current_health = GameManager.player_max_health
	GameManager.emit_signal("health_changed", GameManager.player_current_health, GameManager.player_max_health)
