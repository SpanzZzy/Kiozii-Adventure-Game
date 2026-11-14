extends Node3D

@onready var hud: CanvasLayer = $HUD3D
@onready var player: CharacterBody3D = $Player3D

func _ready() -> void:
	hud.set_level_info(4, "Frozen Ridge", false)
	player.friction = 24.0
	GameManager.reset_for_level(5, false)
