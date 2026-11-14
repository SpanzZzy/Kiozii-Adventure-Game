extends Camera3D

@export var follow_target_path: NodePath
@export var is_3d_mode: bool = true
@export var min_x: float = 12.0
@export var max_x: float = 110.0
@export var is_boss_level: bool = false

var target_node: Node3D = null
var current_x: float = 12.0
var current_y: float = 7.0

func _ready() -> void:
	if not follow_target_path.is_empty():
		target_node = get_node(follow_target_path)
	elif get_tree().get_nodes_in_group("player").size() > 0:
		target_node = get_tree().get_nodes_in_group("player")[0]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		toggle_mode()

func toggle_mode() -> void:
	is_3d_mode = not is_3d_mode

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if not target_node or not is_instance_valid(target_node) or not target_node.is_inside_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0].is_inside_tree():
			target_node = players[0]
		else:
			return

	var target_x: float
	var target_y: float

	if is_boss_level:
		target_x = 23.0
		target_y = 7.8
	else:
		target_x = clampf(target_node.global_position.x + 2.5, min_x, max_x)
		target_y = maxf(5.5, target_node.global_position.y + 4.2)

	current_x += (target_x - current_x) * minf(1.0, delta * 6.5)
	current_y += (target_y - current_y) * minf(1.0, delta * 5.5)

	if is_3d_mode:
		global_position = Vector3(current_x - 1.8, current_y + 3.4, 24.5)
		look_at(Vector3(current_x + 0.8, current_y - 0.6, -1.0), Vector3.UP)
	else:
		global_position = Vector3(current_x, current_y + 1.0, 25.0)
		look_at(Vector3(current_x, current_y, 0.0), Vector3.UP)
