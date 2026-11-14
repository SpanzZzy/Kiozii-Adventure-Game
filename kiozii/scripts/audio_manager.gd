extends Node

var shoot_sfx = preload("res://audio/shoot.wav")
var jump_sfx = preload("res://audio/jump.wav")
var enemy_hit_sfx = preload("res://audio/enemy_hit.wav")
var enemy_die_sfx = preload("res://audio/enemy_die.wav")
var player_hurt_sfx = preload("res://audio/player_hurt.wav")
var portal_unlock_sfx = preload("res://audio/portal_unlock.wav")
var boss_slam_sfx = preload("res://audio/boss_slam.wav")
var victory_sfx = preload("res://audio/victory.wav")

var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8
var current_player: int = 0
var muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if muted or stream == null:
		return
	var player = audio_players[current_player]
	current_player = (current_player + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func play_shoot() -> void: play_sfx(shoot_sfx, -3.0)
func play_jump() -> void: play_sfx(jump_sfx, -2.0)
func play_enemy_hit() -> void: play_sfx(enemy_hit_sfx, -1.0)
func play_enemy_die() -> void: play_sfx(enemy_die_sfx, 0.0)
func play_player_hurt() -> void: play_sfx(player_hurt_sfx, 1.0)
func play_portal_unlock() -> void: play_sfx(portal_unlock_sfx, 0.0)
func play_boss_slam() -> void: play_sfx(boss_slam_sfx, 2.0)
func play_victory() -> void: play_sfx(victory_sfx, 0.0)

func toggle_mute() -> bool:
	muted = not muted
	return muted
