extends Node
func _ready():
    var world_scene = load("res://scenes/world/open_world_mountain.tscn")
    var world = world_scene.instantiate()
    add_child(world)
    var player = world.get_node("Player3D")
    # Trigger victory portal entered
    world._on_victory_portal_entered(player)
