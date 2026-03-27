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

## ── Placeholder definitions ────────────────────────────────────────────────
## Maps bank entry IDs to the placeholder generator that should be used
## when the entry has no real stream assigned.

var _placeholder_map: Dictionary = {
	# Weapon
	&"rifle_fire": "noise_burst",
	&"rifle_dry": "click",
	&"rifle_reload": "tone_short",
	&"rifle_bolt": "click_low",
	&"scope_in": "tone_quiet",
	&"scope_out": "tone_quiet",
	# Impacts
	&"impact_body": "noise_short",
	&"impact_head": "noise_burst",
	&"impact_world": "noise_short",
	&"impact_destructible": "noise_short",
	# Player
	&"hit_taken": "noise_burst",
	&"death": "tone_low",
	# Enemies / NPCs
	&"alert_spotted": "beep",
	&"npc_panic": "beep_fast",
	# Extraction
	&"extraction_start": "beep_pattern",
	&"extraction_complete": "beep_high",
	# Bullet travel
	&"bullet_whizz": "tone_quiet",
	&"bullet_penetrate": "noise_short",
	# UI
	&"menu_click": "click",
	&"menu_hover": "click_quiet",
	&"menu_confirm": "beep_high",
	&"menu_cancel": "tone_low",
	&"ammo_switch": "click_low",
	&"palette_switch": "click",
	&"credits_gain": "beep_high",
	&"xp_gain": "beep",
	# Player movement
	&"footstep": "footstep",
	&"slide": "slide",
	# Breath
	&"heartbeat": "heartbeat",
	&"breath_hold": "breath_in",
	&"breath_exhale": "breath_out",
	# Scope
	&"scope_zoom": "click_quiet",
	# Music / Ambient
	&"hub_theme": "drone",
	&"combat_tension": "drone",
	&"level_ambient": "drone",
	&"level_theme": "drone",
}


func _ready() -> void:
	bank = load(DEFAULT_BANK_PATH) as AudioBank
	_build_bank_map()
	_generate_missing_placeholders()
	_create_pools()
	_create_music_player()
	_create_ambient_player()


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
	## stream, generate a procedural AudioStreamWAV.
	for id: StringName in _placeholder_map:
		var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
		if entry and entry.stream:
			continue  # Real asset exists — skip

		if not entry:
			# Create a new bank entry
			entry = AudioBankEntry.new()
			entry.id = id
			# Default bus assignment
			if id in [&"hub_theme", &"combat_tension"]:
				entry.bus = &"Music"
			elif id == &"level_ambient":
				entry.bus = &"Ambient"
			else:
				entry.bus = &"SFX"
			_bank_map[id] = entry

		# Generate placeholder stream
		var kind: String = _placeholder_map[id]
		entry.stream = _make_placeholder(kind)


func _make_placeholder(kind: String) -> AudioStreamWAV:
	match kind:
		"noise_burst":
			return AudioPlaceholder.noise_burst(0.12, 0.7)
		"noise_short":
			return AudioPlaceholder.noise_burst(0.06, 0.5)
		"click":
			return AudioPlaceholder.click(0.05, 1000.0)
		"click_low":
			return AudioPlaceholder.click(0.06, 600.0)
		"click_quiet":
			return AudioPlaceholder.click(0.04, 1400.0)
		"tone_short":
			return AudioPlaceholder.tone(0.3, 330.0, 0.8)
		"tone_quiet":
			return AudioPlaceholder.tone(0.4, 200.0, 1.0)
		"tone_low":
			return AudioPlaceholder.tone(0.8, 110.0, 0.3)
		"beep":
			return AudioPlaceholder.tone(0.15, 880.0, 1.5)
		"beep_fast":
			return AudioPlaceholder.beep_pattern(2, 0.08, 0.04, 660.0)
		"beep_pattern":
			return AudioPlaceholder.beep_pattern(3, 0.1, 0.05, 880.0)
		"beep_high":
			return AudioPlaceholder.tone(0.2, 1200.0, 1.0)
		"drone":
			return AudioPlaceholder.low_drone(2.0, 60.0)
		"footstep":
			return AudioPlaceholder.noise_burst(0.08, 0.9)
		"slide":
			return AudioPlaceholder.noise_burst(0.3, 0.6)
		"heartbeat":
			return AudioPlaceholder.tone(0.25, 55.0, 2.0)
		"breath_in":
			return AudioPlaceholder.noise_burst(0.4, 0.5)
		"breath_out":
			return AudioPlaceholder.noise_burst(0.3, 0.7)
		_:
			return AudioPlaceholder.click()


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


func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Music"
	add_child(_music_player)


func _create_ambient_player() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = &"Ambient"
	add_child(_ambient_player)


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
	## Crossfade to a new music track. Pass fade_time=0 for instant switch.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return

	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	if fade_time > 0.0 and _music_player.playing:
		# Fade out current, then start new
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_time * 0.5)
		_music_fade_tween.tween_callback(_start_music_track.bind(entry, fade_time * 0.5))
	else:
		_start_music_track(entry, fade_time)


func stop_music(fade_time: float = 1.0) -> void:
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	if fade_time > 0.0 and _music_player.playing:
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		_music_fade_tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func _start_music_track(entry: AudioBankEntry, fade_in_time: float) -> void:
	_music_player.stream = entry.stream
	_music_player.bus = entry.bus

	if fade_in_time > 0.0:
		_music_player.volume_db = -40.0
		_music_player.play()
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(_music_player, "volume_db", entry.volume_db, fade_in_time)
	else:
		_music_player.volume_db = entry.volume_db
		_music_player.play()


## ── Public API: Ambient ────────────────────────────────────────────────────

func play_ambient(id: StringName, fade_time: float = 0.5) -> void:
	## Crossfade to a new ambient track.
	var entry: AudioBankEntry = _bank_map.get(id) as AudioBankEntry
	if not entry or not entry.stream:
		return

	if _ambient_fade_tween and _ambient_fade_tween.is_valid():
		_ambient_fade_tween.kill()

	if fade_time > 0.0 and _ambient_player.playing:
		_ambient_fade_tween = create_tween()
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -40.0, fade_time * 0.5)
		_ambient_fade_tween.tween_callback(_start_ambient_track.bind(entry, fade_time * 0.5))
	else:
		_start_ambient_track(entry, fade_time)


func stop_ambient(fade_time: float = 0.5) -> void:
	if _ambient_fade_tween and _ambient_fade_tween.is_valid():
		_ambient_fade_tween.kill()

	if fade_time > 0.0 and _ambient_player.playing:
		_ambient_fade_tween = create_tween()
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -40.0, fade_time)
		_ambient_fade_tween.tween_callback(_ambient_player.stop)
	else:
		_ambient_player.stop()


func _start_ambient_track(entry: AudioBankEntry, fade_in_time: float) -> void:
	_ambient_player.stream = entry.stream
	_ambient_player.bus = entry.bus

	if fade_in_time > 0.0:
		_ambient_player.volume_db = -40.0
		_ambient_player.play()
		_ambient_fade_tween = create_tween()
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", entry.volume_db, fade_in_time)
	else:
		_ambient_player.volume_db = entry.volume_db
		_ambient_player.play()


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
