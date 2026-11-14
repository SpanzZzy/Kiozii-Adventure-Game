extends Node3D

@onready var hud: CanvasLayer = $HUD3D
@onready var player: CharacterBody3D = $Player3D

func _ready() -> void:
	hud.set_level_info(7, "The Final Summit", true)
	player.friction = 90.0
	GameManager.reset_for_level(1, true)
