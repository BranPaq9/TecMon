extends Node

@export var sfx_pool_size: int = 16

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in sfx_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		
func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()
	
func stop_music() -> void:
	music_player.stop()
	
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := _get_free_sfx_player()

	if player == null:
		return

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player

	# Optional: steal the oldest/busiest player instead of dropping the sound
	return sfx_players[0]
	
func set_music_volume(value: float) -> void:
	_set_bus_volume("Music", value)

func set_sfx_volume(value: float) -> void:
	_set_bus_volume("SFX", value)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	value = clamp(value, 0.0, 1.0)

	if value == 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
