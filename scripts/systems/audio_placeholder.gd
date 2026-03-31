class_name AudioPlaceholder
extends RefCounted
## Generates simple placeholder AudioStreamWAV samples at runtime.
## Used by AudioManager when a bank entry has no real audio file assigned.
##
## Also holds the placeholder mapping table (which bank IDs map to which
## placeholder kind) so AudioManager stays focused on playback.

const SAMPLE_RATE: int = 22050
const MIX_RATE: int = 22050


## ── Placeholder map ──────────────────────────────────────────────────────────
## Maps bank entry IDs to the placeholder generator kind.
## When an entry has no real stream, this table decides what to generate.

static var PLACEHOLDER_MAP: Dictionary = {
	# Weapon
	&"rifle_fire": "noise_burst",
	&"rifle_fire_suppressed": "suppressed_shot",
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


## ── Factory ──────────────────────────────────────────────────────────────────

static func make_placeholder(kind: String) -> AudioStreamWAV:
	## Creates a placeholder AudioStreamWAV for the given kind string.
	match kind:
		"suppressed_shot":
			return noise_burst(0.08, 0.3)
		"noise_burst":
			return noise_burst(0.12, 0.7)
		"noise_short":
			return noise_burst(0.06, 0.5)
		"click":
			return click(0.05, 1000.0)
		"click_low":
			return click(0.06, 600.0)
		"click_quiet":
			return click(0.04, 1400.0)
		"tone_short":
			return tone(0.3, 330.0, 0.8)
		"tone_quiet":
			return tone(0.4, 200.0, 1.0)
		"tone_low":
			return tone(0.8, 110.0, 0.3)
		"beep":
			return tone(0.15, 880.0, 1.5)
		"beep_fast":
			return beep_pattern(2, 0.08, 0.04, 660.0)
		"beep_pattern":
			return beep_pattern(3, 0.1, 0.05, 880.0)
		"beep_high":
			return tone(0.2, 1200.0, 1.0)
		"drone":
			return low_drone(2.0, 60.0)
		"footstep":
			return noise_burst(0.08, 0.9)
		"slide":
			return noise_burst(0.3, 0.6)
		"heartbeat":
			return tone(0.25, 55.0, 2.0)
		"breath_in":
			return noise_burst(0.4, 0.5)
		"breath_out":
			return noise_burst(0.3, 0.7)
		_:
			return click()


## ── Waveform generators ──────────────────────────────────────────────────────

static func noise_burst(duration: float = 0.1, volume: float = 0.8) -> AudioStreamWAV:
	## Short white-noise burst — placeholder for gunshots, impacts.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit = 2 bytes per sample

	for i in sample_count:
		var t: float = float(i) / float(sample_count)
		var envelope: float = (1.0 - t) * volume  # Linear decay
		var sample: float = randf_range(-1.0, 1.0) * envelope
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


static func click(duration: float = 0.02, freq: float = 1000.0) -> AudioStreamWAV:
	## Very short click — placeholder for UI interactions.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(sample_count)
		var envelope: float = (1.0 - t * t) * 0.9  # Quick quadratic falloff, strong start
		var sample: float = sin(t * freq * TAU / float(SAMPLE_RATE)) * envelope
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


static func tone(duration: float = 0.5, freq: float = 220.0, decay: float = 0.5) -> AudioStreamWAV:
	## Decaying sine tone — placeholder for ambient, music, alerts.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(sample_count)
		var envelope: float = pow(1.0 - t, decay) * 0.6
		var sample: float = sin(t * freq * TAU * duration) * envelope
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


static func beep_pattern(beep_count: int = 3, beep_duration: float = 0.1,
		gap_duration: float = 0.05, freq: float = 880.0) -> AudioStreamWAV:
	## Series of short beeps — placeholder for extraction, alerts.
	var total_duration: float = beep_count * beep_duration + (beep_count - 1) * gap_duration
	var sample_count: int = int(SAMPLE_RATE * total_duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		# Determine which beep (or gap) we're in
		var cycle_length: float = beep_duration + gap_duration
		var pos_in_cycle: float = fmod(t, cycle_length)
		if pos_in_cycle < beep_duration:
			var env: float = 0.5 * (1.0 - pos_in_cycle / beep_duration)
			sample = sin(t * freq * TAU) * env

		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav


static func low_drone(duration: float = 2.0, freq: float = 60.0) -> AudioStreamWAV:
	## Low continuous tone — placeholder for ambient loops.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = sin(t * freq * TAU) * 0.3
		sample += sin(t * freq * 1.5 * TAU) * 0.15  # Slight harmonic
		# Fade in/out
		var fade_samples: int = int(SAMPLE_RATE * 0.1)
		var env: float = 1.0
		if i < fade_samples:
			env = float(i) / float(fade_samples)
		elif i > sample_count - fade_samples:
			env = float(sample_count - i) / float(fade_samples)
		sample *= env

		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = sample_count
	wav.data = data
	return wav
