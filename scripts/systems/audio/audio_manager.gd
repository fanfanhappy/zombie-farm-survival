class_name GameAudioManager
extends Node

const SETTINGS_PATH := "user://audio_settings.cfg"

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer


func _ready() -> void:
	_load_settings()


func set_bus_volume_percent(bus_name: StringName, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0: return
	var normalized := clampf(percent, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, normalized <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(normalized, 0.0001)))
	_save_settings()


func get_bus_volume_percent(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index): return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


func play_music(stream: AudioStream, restart := false) -> void:
	if stream == null: return
	if music_player.stream == stream and music_player.playing and not restart: return
	music_player.stream = stream
	music_player.play()


func play_ambience(stream: AudioStream) -> void:
	if stream == null: return
	ambience_player.stream = stream
	ambience_player.play()


func play_sfx(stream: AudioStream, bus: StringName = &"SFX") -> void:
	if stream == null: return
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name in [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]:
		config.set_value("volume", String(bus_name), get_bus_volume_percent(bus_name))
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK: return
	for bus_name in [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]:
		set_bus_volume_percent(bus_name, float(config.get_value("volume", String(bus_name), 1.0)))
