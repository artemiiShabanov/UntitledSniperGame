extends Node
## Autoloaded singleton — stores and applies user settings (sensitivity, audio, video).
## Saves to user://settings.cfg, separate from game save data.

const SETTINGS_PATH := "user://settings.cfg"

## Defaults
var mouse_sensitivity: float = 0.002
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var fullscreen: bool = true
var vsync: bool = true


func _ready() -> void:
	load_settings()
	apply_all()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # Use defaults
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	master_volume = config.get_value("audio", "master_volume", master_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	vsync = config.get_value("video", "vsync", vsync)


func apply_all() -> void:
	_apply_audio()
	_apply_video()


func _apply_audio() -> void:
	# Master bus = index 0
	var master_db := linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(0, master_db)
	# SFX and Music buses (if they exist)
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume) if sfx_volume > 0.0 else -80.0)
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume) if music_volume > 0.0 else -80.0)
	# Ambient bus follows the SFX volume (or could be separate later)
	var ambient_idx := AudioServer.get_bus_index("Ambient")
	if ambient_idx >= 0:
		AudioServer.set_bus_volume_db(ambient_idx, linear_to_db(sfx_volume) if sfx_volume > 0.0 else -80.0)


func _apply_video() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
