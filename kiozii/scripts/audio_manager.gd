extends Node

# retro audio manager
var shoot_sfx = preload("res://audio/shoot.wav")
var jump_sfx = preload("res://audio/jump.wav")
var enemy_hit_sfx = preload("res://audio/enemy_hit.wav")
var enemy_die_sfx = preload("res://audio/enemy_die.wav")
var player_hurt_sfx = preload("res://audio/player_hurt.wav")
var portal_unlock_sfx = preload("res://audio/portal_unlock.wav")
var boss_slam_sfx = preload("res://audio/boss_slam.wav")
var victory_sfx = preload("res://audio/victory.wav")
var crystal_sfx = preload("res://audio/crystal.wav")
var checkpoint_sfx = preload("res://audio/checkpoint.wav")
var second_wind_sfx = preload("res://audio/second_wind.wav")

# level ambience streams
var ambient_streams = {
	1: preload("res://audio/ambience_highlands.wav"),
	2: preload("res://audio/ambience_autumn.wav"),
	3: preload("res://audio/ambience_canyon.wav"),
	4: preload("res://audio/ambience_frozen.wav"),
	5: preload("res://audio/ambience_crystals.wav"),
	6: preload("res://audio/ambience_embers.wav"),
	7: preload("res://audio/ambience_summit.wav")
}

var audio_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer = null
const POOL_SIZE = 8
var current_player: int = 0
var muted: bool = false

var master_vol_db: float = 0.0
var music_vol_db: float = 0.0
var sfx_vol_db: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)
		
	# dedicated ambience loop player
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.finished.connect(Callable(self, "_on_ambient_finished"))

func _on_ambient_finished() -> void:
	if ambient_player and ambient_player.stream and not muted:
		ambient_player.play()

func set_volumes(m: float, mus: float, s: float) -> void:
	master_vol_db = linear_to_db(clampf(m, 0.0001, 1.0))
	music_vol_db = linear_to_db(clampf(mus, 0.0001, 1.0))
	sfx_vol_db = linear_to_db(clampf(s, 0.0001, 1.0))
	if ambient_player and ambient_player.playing:
		ambient_player.volume_db = -9.0 + music_vol_db + master_vol_db

func play_sfx(stream: AudioStream, base_volume_db: float = 0.0) -> void:
	if muted or stream == null:
		return
	var player = audio_players[current_player]
	current_player = (current_player + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = base_volume_db + sfx_vol_db + master_vol_db
	player.play()

func play_level_ambience(level_idx: int) -> void:
	if muted:
		return
	var stream = ambient_streams.get(level_idx, null)
	if stream and ambient_player:
		if ambient_player.stream != stream:
			ambient_player.stream = stream
		ambient_player.volume_db = -9.0 + music_vol_db + master_vol_db
		if not ambient_player.playing:
			ambient_player.play()

func stop_level_ambience() -> void:
	if ambient_player:
		ambient_player.stop()

func play_shoot() -> void: play_sfx(shoot_sfx, -3.0)
func play_jump() -> void: play_sfx(jump_sfx, -2.0)
func play_enemy_hit() -> void: play_sfx(enemy_hit_sfx, -1.0)
func play_enemy_die() -> void: play_sfx(enemy_die_sfx, 0.0)
func play_player_hurt() -> void: play_sfx(player_hurt_sfx, 1.0)
func play_portal_unlock() -> void: play_sfx(portal_unlock_sfx, 0.0)
func play_boss_slam() -> void: play_sfx(boss_slam_sfx, 2.0)
func play_victory() -> void: play_sfx(victory_sfx, 0.0)
func play_crystal() -> void: play_sfx(crystal_sfx, 1.0)
func play_checkpoint() -> void: play_sfx(checkpoint_sfx, 1.0)
func play_second_wind() -> void: play_sfx(second_wind_sfx, 1.5)

func toggle_mute() -> bool:
	muted = not muted
	if muted and ambient_player:
		ambient_player.stop()
	elif not muted and ambient_player and ambient_player.stream:
		ambient_player.play()
	return muted
