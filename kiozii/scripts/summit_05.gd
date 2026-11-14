extends Node3D

@onready var hud: CanvasLayer = $HUD3D
@onready var player: CharacterBody3D = $Player3D

func _ready() -> void:
	hud.set_level_info(5, "Crystal Mountains", false)
	player.friction = 85.0
	GameManager.reset_for_level(6, false)
