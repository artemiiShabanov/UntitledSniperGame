extends Node
## Central audio API — autoloaded singleton.
## Provides object-pooled 2D/3D SFX playback, music, and ambient with crossfading.
## Sounds are looked up by StringName from an AudioBank resource.
## Entries with null streams get auto-generated placeholders at startup.

## ── Pool sizes ──────────────────────────────────────────────────────────────

const POOL_3D_SIZE: int = 16
const POOL_2D_SIZE: int = 8

## ── The sound bank ─────────────────────────────────────────────────────────

const DEFAULT_BANK_PATH: String = "res://data/audio/default_bank.tres"

var bank: AudioBank

var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_2d: Array[AudioStreamPlayer] = []
var _bank_map: Dictionary = {}  ## StringName -> AudioBankEntry

var _music_player: AudioStreamPlayer
var _music_fade_tween: Tween = null
var _ambient_player: AudioStreamPlayer
var _ambient_fade_tween: Tween = null


func _ready() -> void:
	bank = load(DEFAULT_BANK_PATH) as AudioBank
	_build_bank_map()
	_generate_missing_placeholders()
	_create_pools()
	_music_player = _create_track_player("MusicPlayer", &"Music")
	_ambient_player = _create_track_player("AmbientPlayer", &"Ambient")


## ── Bank setup ─────────────────────────────────────────────────────────────

func _build_bank_map() -> void:
	_bank_map.clear()
	if not bank:
		return
	for entry: AudioBankEntry in bank.entries:
		if entry and entry.id != &"":
			_bank_map[entry.id] = entry


func _generate_missing_placeholders() -> void:
	## For every placeholder ID that is either missing from the bank or has a null
	## stream, generate a procedural AudioStreamWAV via AudioPlaceholder.
	for id: StringName in AudioPlaceholder.PLACEHOLDER_MAP:
		var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
		if entry and entry.stream:
			continue  # Real asset exists — skip

		if not entry:
			# Create a new bank entry
			entry = AudioBankEntry.new()
			entry.id = id
			# Default bus assignment
			if id in [&"hub_theme", &"combat_tension", &"level_theme"]:
				entry.bus = &"Music"
			elif id in [&"level_ambient"]:
				entry.bus = &"Ambient"
			else:
				entry.bus = &"SFX"
			_bank_map[id] = entry

		# Generate placeholder stream
		var kind: String = AudioPlaceholder.PLACEHOLDER_MAP[id]
		entry.stream = AudioPlaceholder.make_placeholder(kind)


## ── Pool creation ──────────────────────────────────────────────────────────

func _create_pools() -> void:
	for i in POOL_3D_SIZE:
		var player := AudioStreamPlayer3D.new()
		player.name = "SFX3D_%d" % i
		player.bus = &"SFX"
		add_child(player)
		_pool_3d.append(player)

	for i in POOL_2D_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX2D_%d" % i
		player.bus = &"SFX"
		add_child(player)
		_pool_2d.append(player)


func _create_track_player(player_name: String, bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	add_child(player)
	return player


## ── Public API: SFX ────────────────────────────────────────────────────────

func play_sfx(id: StringName, position: Vector3 = Vector3.ZERO) -> void:
	## Play a 3D positional sound effect at the given world position.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return

	var player: AudioStreamPlayer3D = _get_free_3d_player()
	if not player:
		return

	player.stream = entry.stream
	player.volume_db = entry.volume_db
	player.bus = entry.bus
	player.global_position = position

	if entry.pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-entry.pitch_variance, entry.pitch_variance)
	else:
		player.pitch_scale = 1.0

	player.play()


func play_sfx_2d(id: StringName) -> void:
	## Play a non-positional 2D sound effect (UI, player actions).
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return

	var player: AudioStreamPlayer = _get_free_2d_player()
	if not player:
		return

	player.stream = entry.stream
	player.volume_db = entry.volume_db
	player.bus = entry.bus

	if entry.pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-entry.pitch_variance, entry.pitch_variance)
	else:
		player.pitch_scale = 1.0

	player.play()


func play_sfx_2d_varied(id: StringName, pitch_range: float = 0.15, volume_offset: float = 0.0) -> void:
	## Play a 2D sound with random pitch variation and optional volume offset.
	## Used for footsteps, heartbeats, etc. to prevent repetitive feel.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return

	var player: AudioStreamPlayer = _get_free_2d_player()
	if not player:
		return

	player.stream = entry.stream
	player.volume_db = entry.volume_db + volume_offset + randf_range(-1.5, 1.5)
	player.bus = entry.bus
	player.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	player.play()


## ── Public API: Music ──────────────────────────────────────────────────────

func play_music(id: StringName, fade_time: float = 1.0) -> void:
	## Crossfade to a new music track from the bank.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return
	_crossfade_track(_music_player, entry, fade_time, "_music_fade_tween")


func play_music_stream(stream: AudioStream, volume_db: float = -12.0, fade_time: float = 1.0) -> void:
	## Play a music track directly from an AudioStream (for per-level themes).
	if not stream:
		return
	var entry := AudioBankEntry.new()
	entry.stream = stream
	entry.volume_db = volume_db
	entry.bus = &"Music"
	_crossfade_track(_music_player, entry, fade_time, "_music_fade_tween")


func stop_music(fade_time: float = 1.0) -> void:
	_stop_track(_music_player, fade_time, "_music_fade_tween")


## ── Public API: Ambient ────────────────────────────────────────────────────

func play_ambient(id: StringName, fade_time: float = 0.5) -> void:
	## Crossfade to a new ambient track from the bank.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return
	_crossfade_track(_ambient_player, entry, fade_time, "_ambient_fade_tween")


func play_ambient_stream(stream: AudioStream, volume_db: float = -9.0, fade_time: float = 0.5) -> void:
	## Play an ambient track directly from an AudioStream (for per-level ambience).
	if not stream:
		return
	var entry := AudioBankEntry.new()
	entry.stream = stream
	entry.volume_db = volume_db
	entry.bus = &"Ambient"
	_crossfade_track(_ambient_player, entry, fade_time, "_ambient_fade_tween")


func stop_ambient(fade_time: float = 0.5) -> void:
	_stop_track(_ambient_player, fade_time, "_ambient_fade_tween")


## ── Crossfade engine (shared by music & ambient) ──────────────────────────

func _crossfade_track(player: AudioStreamPlayer, entry: AudioBankEntry,
		fade_time: float, tween_prop: String) -> void:
	## Crossfades `player` to a new track. Reuses the same pattern for both
	## music and ambient channels, eliminating duplication.
	var existing_tween: Tween = get(tween_prop)
	if existing_tween and existing_tween.is_valid():
		existing_tween.kill()

	if fade_time > 0.0 and player.playing:
		# Fade out current, then start new
		var tw := create_tween()
		set(tween_prop, tw)
		tw.tween_property(player, "volume_db", -40.0, fade_time * 0.5)
		tw.tween_callback(_start_track.bind(player, entry, fade_time * 0.5, tween_prop))
	else:
		_start_track(player, entry, fade_time, tween_prop)


func _start_track(player: AudioStreamPlayer, entry: AudioBankEntry,
		fade_in_time: float, tween_prop: String) -> void:
	player.stream = entry.stream
	player.bus = entry.bus

	if fade_in_time > 0.0:
		player.volume_db = -40.0
		player.play()
		var tw := create_tween()
		set(tween_prop, tw)
		tw.tween_property(player, "volume_db", entry.volume_db, fade_in_time)
	else:
		player.volume_db = entry.volume_db
		player.play()


func _stop_track(player: AudioStreamPlayer, fade_time: float, tween_prop: String) -> void:
	var existing_tween: Tween = get(tween_prop)
	if existing_tween and existing_tween.is_valid():
		existing_tween.kill()

	if fade_time > 0.0 and player.playing:
		var tw := create_tween()
		set(tween_prop, tw)
		tw.tween_property(player, "volume_db", -40.0, fade_time)
		tw.tween_callback(player.stop)
	else:
		player.stop()


## ── Pool helpers ───────────────────────────────────────────────────────────

func _get_free_3d_player() -> AudioStreamPlayer3D:
	for player: AudioStreamPlayer3D in _pool_3d:
		if not player.playing:
			return player
	# All busy — steal the oldest (first in array)
	return _pool_3d[0]


func _get_free_2d_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _pool_2d:
		if not player.playing:
			return player
	# All busy — steal the oldest
	return _pool_2d[0]


## ── Button sound helpers ─────────────────────────────────────────────────

func wire_button(btn: BaseButton, click_id: StringName = &"menu_click") -> void:
	## Connects click + hover sounds to any button. Call once in _ready().
	btn.pressed.connect(func() -> void: play_sfx_2d(click_id))
	btn.mouse_entered.connect(func() -> void: play_sfx_2d(&"menu_hover"))


func wire_buttons(container: Node, click_id: StringName = &"menu_click") -> void:
	## Recursively wires click + hover sounds to all buttons in a container.
	for child in container.get_children():
		if child is BaseButton:
			wire_button(child, click_id)
		if child.get_child_count() > 0:
			wire_buttons(child, click_id)
