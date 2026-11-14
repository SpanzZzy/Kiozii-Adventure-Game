extends Node3D

@onready var hud: CanvasLayer = $HUD3D
@onready var player: CharacterBody3D = $Player3D
@onready var boss = $Enemies/Enemy_0

func _ready() -> void:
	hud.set_level_info(7, "The Final Summit", true)
	player.friction = 90.0
	GameManager.reset_for_level(1, true)
	if boss and boss.has_signal("boss_health_changed"):
		if not boss.boss_health_changed.is_connected(hud._on_boss_health_changed):
			boss.boss_health_changed.connect(hud._on_boss_health_changed)
