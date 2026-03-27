@tool
extends EditorScript
## Sound Generator — run from Editor > Run Script (Ctrl+Shift+X)
## Generates sfxr-style WAV files for UI and weapon audio banks.
## Tweak parameters below, re-run, listen. When happy, they auto-load
## into the bank because default_bank.tres entries point at these paths.
##
## Output: res://data/audio/generated/<bank_id>.wav

const SAMPLE_RATE: int = 44100
const OUTPUT_DIR: String = "res://data/audio/generated"


## ── Sound definitions ─────────────────────────────────────────────────────
## Each entry: { "func": callable_name, ...params }
## Tweak any parameter and re-run to regenerate.

var SOUNDS: Dictionary = {
	"menu_click": {
		"type": "sweep",
		"wave": "square",
		"freq_start": 800.0,
		"freq_end": 400.0,
		"duration": 0.05,
		"volume": 0.7,
		"decay": 3.0,
	},
	"menu_hover": {
		"type": "tone",
		"wave": "sine",
		"freq": 1200.0,
		"duration": 0.035,
		"volume": 0.35,
		"decay": 2.0,
	},
	"menu_confirm": {
		"type": "two_tone",
		"wave": "sine",
		"freq_a": 440.0,
		"freq_b": 880.0,
		"duration_each": 0.07,
		"gap": 0.02,
		"volume": 0.6,
		"decay": 2.0,
	},
	"menu_cancel": {
		"type": "two_tone",
		"wave": "sine",
		"freq_a": 880.0,
		"freq_b": 440.0,
		"duration_each": 0.07,
		"gap": 0.02,
		"volume": 0.6,
		"decay": 2.0,
	},
	"ammo_switch": {
		"type": "noise_click",
		"freq": 500.0,
		"duration": 0.04,
		"noise_mix": 0.3,
		"volume": 0.65,
		"decay": 4.0,
	},
	"palette_switch": {
		"type": "sweep",
		"wave": "sine",
		"freq_start": 200.0,
		"freq_end": 1200.0,
		"duration": 0.12,
		"volume": 0.45,
		"decay": 1.5,
	},
	"credits_gain": {
		"type": "pling",
		"freq": 1200.0,
		"harmonic": 2400.0,
		"duration": 0.2,
		"volume": 0.55,
		"decay": 2.5,
	},
	"xp_gain": {
		"type": "triple_beep",
		"freqs": [660.0, 880.0, 1100.0],
		"beep_duration": 0.06,
		"gap": 0.03,
		"volume": 0.5,
		"decay": 2.5,
	},

	# ── Weapon sounds ────────────────────────────────────────────────────
	"rifle_fire": {
		"type": "rifle_shot",
		"crack_freq": 120.0,        # Low boom frequency
		"crack_duration": 0.04,     # Initial crack length
		"boom_freq": 60.0,          # Sub-bass thump
		"boom_duration": 0.15,      # Boom body
		"tail_duration": 0.6,       # Echo/reverb tail
		"noise_mix": 0.7,           # How much noise vs tone (0-1)
		"volume": 0.9,
	},
	"rifle_bolt": {
		"type": "bolt_action",
		"click_freq": 2200.0,       # Metallic click pitch
		"slide_freq_start": 800.0,  # Slide up
		"slide_freq_end": 1600.0,   # Slide end
		"click_duration": 0.015,    # Initial click
		"slide_duration": 0.08,     # Slide/rack
		"return_duration": 0.06,    # Return click
		"gap": 0.04,                # Gap between slide and return
		"volume": 0.6,
	},
	"rifle_dry": {
		"type": "noise_click",
		"freq": 1800.0,
		"duration": 0.025,
		"noise_mix": 0.4,
		"volume": 0.5,
		"decay": 5.0,
	},
	"rifle_reload": {
		"type": "reload",
		"mag_out_freq": 600.0,      # Magazine eject pitch
		"mag_in_freq": 900.0,       # Magazine insert pitch
		"bolt_freq": 1400.0,        # Final bolt rack
		"mag_out_dur": 0.06,        # Eject duration
		"gap_1": 0.15,              # Pause while swapping
		"mag_in_dur": 0.05,         # Insert click duration
		"gap_2": 0.08,              # Pause before bolt
		"bolt_dur": 0.04,           # Bolt rack duration
		"volume": 0.6,
	},
	"scope_in": {
		"type": "sweep",
		"wave": "sine",
		"freq_start": 400.0,
		"freq_end": 800.0,
		"duration": 0.15,
		"volume": 0.25,
		"decay": 2.0,
	},
	"scope_out": {
		"type": "sweep",
		"wave": "sine",
		"freq_start": 800.0,
		"freq_end": 400.0,
		"duration": 0.12,
		"volume": 0.25,
		"decay": 2.0,
	},

}


## ── Main ──────────────────────────────────────────────────────────────────

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	for id: String in SOUNDS:
		var params: Dictionary = SOUNDS[id]
		var samples: PackedFloat32Array = _generate(params)
		var path: String = OUTPUT_DIR + "/" + id + ".wav"
		_save_wav(path, samples)
		print("  Generated: %s  (%d samples, %.3fs)" % [path, samples.size(), samples.size() / float(SAMPLE_RATE)])

	print("Done! %d UI sounds generated in %s" % [SOUNDS.size(), OUTPUT_DIR])
	print("Assign them to bank entries in default_bank.tres via the Inspector.")


## ── Generators ────────────────────────────────────────────────────────────

func _generate(params: Dictionary) -> PackedFloat32Array:
	match params["type"]:
		"sweep":
			return _gen_sweep(params)
		"tone":
			return _gen_tone(params)
		"two_tone":
			return _gen_two_tone(params)
		"noise_click":
			return _gen_noise_click(params)
		"pling":
			return _gen_pling(params)
		"triple_beep":
			return _gen_triple_beep(params)
		"rifle_shot":
			return _gen_rifle_shot(params)
		"bolt_action":
			return _gen_bolt_action(params)
		"reload":
			return _gen_reload(params)
		"impact":
			return _gen_impact(params)
		"ricochet":
			return _gen_ricochet(params)
		"drone_loop":
			return _gen_drone_loop(params)
		_:
			push_error("Unknown sound type: %s" % params["type"])
			return PackedFloat32Array()


func _gen_sweep(p: Dictionary) -> PackedFloat32Array:
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var f0: float = p["freq_start"]
	var f1: float = p["freq_end"]
	var vol: float = p["volume"]
	var decay: float = p["decay"]
	var wave: String = p.get("wave", "sine")

	for i in count:
		var t: float = float(i) / float(count)
		var freq: float = lerp(f0, f1, t)
		var phase: float = float(i) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - t, decay) * vol
		out[i] = _oscillate(wave, phase, freq) * env
	return out


func _gen_tone(p: Dictionary) -> PackedFloat32Array:
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var freq: float = p["freq"]
	var vol: float = p["volume"]
	var decay: float = p["decay"]
	var wave: String = p.get("wave", "sine")

	for i in count:
		var t: float = float(i) / float(count)
		var phase: float = float(i) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - t, decay) * vol
		out[i] = _oscillate(wave, phase, freq) * env
	return out


func _gen_two_tone(p: Dictionary) -> PackedFloat32Array:
	var dur_each: float = p["duration_each"]
	var gap: float = p["gap"]
	var total: float = dur_each * 2.0 + gap
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var fa: float = p["freq_a"]
	var fb: float = p["freq_b"]
	var vol: float = p["volume"]
	var decay: float = p["decay"]
	var wave: String = p.get("wave", "sine")

	var gap_start: int = int(SAMPLE_RATE * dur_each)
	var gap_end: int = int(SAMPLE_RATE * (dur_each + gap))

	for i in count:
		var phase: float = float(i) / float(SAMPLE_RATE)
		if i < gap_start:
			# First tone
			var t: float = float(i) / float(gap_start)
			var env: float = pow(1.0 - t, decay) * vol
			out[i] = _oscillate(wave, phase, fa) * env
		elif i >= gap_end:
			# Second tone
			var local_i: int = i - gap_end
			var local_count: int = count - gap_end
			var t: float = float(local_i) / float(local_count)
			var env: float = pow(1.0 - t, decay) * vol
			out[i] = _oscillate(wave, phase, fb) * env
		# else: gap — silent
	return out


func _gen_noise_click(p: Dictionary) -> PackedFloat32Array:
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var freq: float = p["freq"]
	var vol: float = p["volume"]
	var decay: float = p["decay"]
	var noise_mix: float = p["noise_mix"]

	for i in count:
		var t: float = float(i) / float(count)
		var phase: float = float(i) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - t, decay) * vol
		var tone_part: float = _oscillate("square", phase, freq)
		var noise_part: float = randf_range(-1.0, 1.0)
		out[i] = (tone_part * (1.0 - noise_mix) + noise_part * noise_mix) * env
	return out


func _gen_pling(p: Dictionary) -> PackedFloat32Array:
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var freq: float = p["freq"]
	var harmonic: float = p["harmonic"]
	var vol: float = p["volume"]
	var decay: float = p["decay"]

	for i in count:
		var t: float = float(i) / float(count)
		var phase: float = float(i) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - t, decay) * vol
		var s: float = sin(phase * freq * TAU) * 0.7 + sin(phase * harmonic * TAU) * 0.3
		out[i] = s * env
	return out


func _gen_triple_beep(p: Dictionary) -> PackedFloat32Array:
	var freqs: Array = p["freqs"]
	var beep_dur: float = p["beep_duration"]
	var gap: float = p["gap"]
	var total: float = freqs.size() * beep_dur + (freqs.size() - 1) * gap
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var decay: float = p["decay"]

	for i in count:
		var time: float = float(i) / float(SAMPLE_RATE)
		var cycle: float = beep_dur + gap
		var beep_index: int = int(time / cycle)
		var pos_in_cycle: float = fmod(time, cycle)

		if beep_index < freqs.size() and pos_in_cycle < beep_dur:
			var t: float = pos_in_cycle / beep_dur
			var env: float = pow(1.0 - t, decay) * vol
			var freq: float = freqs[beep_index]
			out[i] = sin(time * freq * TAU) * env
	return out


## ── Weapon generators ─────────────────────────────────────────────────────

func _gen_rifle_shot(p: Dictionary) -> PackedFloat32Array:
	## Layered: initial noise crack → low-freq boom → filtered noise tail
	var crack_dur: float = p["crack_duration"]
	var boom_dur: float = p["boom_duration"]
	var tail_dur: float = p["tail_duration"]
	var total: float = crack_dur + boom_dur + tail_dur
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var crack_freq: float = p["crack_freq"]
	var boom_freq: float = p["boom_freq"]
	var noise_mix: float = p["noise_mix"]

	var crack_end: int = int(SAMPLE_RATE * crack_dur)
	var boom_end: int = int(SAMPLE_RATE * (crack_dur + boom_dur))

	for i in count:
		var t_global: float = float(i) / float(count)
		var phase: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		if i < crack_end:
			# Sharp initial crack — mostly noise + high-freq transient
			var t: float = float(i) / float(crack_end)
			var env: float = (1.0 - t) * vol
			var noise: float = randf_range(-1.0, 1.0)
			var tone: float = sin(phase * crack_freq * 4.0 * TAU)
			sample = (noise * noise_mix + tone * (1.0 - noise_mix)) * env
		elif i < boom_end:
			# Low-frequency boom body
			var local_t: float = float(i - crack_end) / float(boom_end - crack_end)
			var env: float = pow(1.0 - local_t, 1.5) * vol * 0.8
			var boom: float = sin(phase * boom_freq * TAU)
			var noise: float = randf_range(-1.0, 1.0) * 0.3
			sample = (boom * 0.7 + noise) * env
		else:
			# Filtered noise tail — reverb/echo simulation
			var local_t: float = float(i - boom_end) / float(count - boom_end)
			var env: float = pow(1.0 - local_t, 2.5) * vol * 0.35
			var noise: float = randf_range(-1.0, 1.0)
			# Simulated low-pass: blend with previous sample
			var prev: float = out[i - 1] if i > 0 else 0.0
			sample = (noise * 0.3 + prev * 0.7) * env

		out[i] = clampf(sample, -1.0, 1.0)
	return out


func _gen_bolt_action(p: Dictionary) -> PackedFloat32Array:
	## Click → slide → gap → return click
	var click_dur: float = p["click_duration"]
	var slide_dur: float = p["slide_duration"]
	var gap: float = p["gap"]
	var ret_dur: float = p["return_duration"]
	var total: float = click_dur + slide_dur + gap + ret_dur
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var click_freq: float = p["click_freq"]
	var slide_f0: float = p["slide_freq_start"]
	var slide_f1: float = p["slide_freq_end"]

	var s1: int = int(SAMPLE_RATE * click_dur)
	var s2: int = s1 + int(SAMPLE_RATE * slide_dur)
	var s3: int = s2 + int(SAMPLE_RATE * gap)

	for i in count:
		var phase: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		if i < s1:
			# Initial click — sharp metallic transient
			var t: float = float(i) / float(s1)
			var env: float = pow(1.0 - t, 6.0) * vol
			sample = (sin(phase * click_freq * TAU) * 0.6 + randf_range(-1.0, 1.0) * 0.4) * env
		elif i < s2:
			# Slide — frequency sweep with metallic noise
			var t: float = float(i - s1) / float(s2 - s1)
			var env: float = pow(1.0 - t, 2.0) * vol * 0.5
			var freq: float = lerp(slide_f0, slide_f1, t)
			sample = (sin(phase * freq * TAU) * 0.5 + randf_range(-1.0, 1.0) * 0.5) * env
		elif i >= s3:
			# Return click — snappier than initial
			var local_i: int = i - s3
			var local_count: int = count - s3
			var t: float = float(local_i) / float(local_count)
			var env: float = pow(1.0 - t, 8.0) * vol * 0.8
			sample = (sin(phase * click_freq * 1.2 * TAU) * 0.5 + randf_range(-1.0, 1.0) * 0.5) * env

		out[i] = clampf(sample, -1.0, 1.0)
	return out


func _gen_reload(p: Dictionary) -> PackedFloat32Array:
	## Mag out click → pause → mag in click → pause → bolt rack
	var d1: float = p["mag_out_dur"]
	var g1: float = p["gap_1"]
	var d2: float = p["mag_in_dur"]
	var g2: float = p["gap_2"]
	var d3: float = p["bolt_dur"]
	var total: float = d1 + g1 + d2 + g2 + d3
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var f1: float = p["mag_out_freq"]
	var f2: float = p["mag_in_freq"]
	var f3: float = p["bolt_freq"]

	var e1: int = int(SAMPLE_RATE * d1)
	var e2: int = e1 + int(SAMPLE_RATE * g1)
	var e3: int = e2 + int(SAMPLE_RATE * d2)
	var e4: int = e3 + int(SAMPLE_RATE * g2)

	for i in count:
		var phase: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		if i < e1:
			# Mag out — descending metallic click
			var t: float = float(i) / float(e1)
			var env: float = pow(1.0 - t, 4.0) * vol
			var freq: float = lerp(f1, f1 * 0.5, t)
			sample = (sin(phase * freq * TAU) * 0.5 + randf_range(-1.0, 1.0) * 0.5) * env
		elif i >= e2 and i < e3:
			# Mag in — sharper, ascending
			var t: float = float(i - e2) / float(e3 - e2)
			var env: float = pow(1.0 - t, 5.0) * vol * 0.9
			var freq: float = lerp(f2 * 0.8, f2, t)
			sample = (sin(phase * freq * TAU) * 0.4 + randf_range(-1.0, 1.0) * 0.6) * env
		elif i >= e4:
			# Bolt rack — sharp metallic
			var local_t: float = float(i - e4) / float(count - e4)
			var env: float = pow(1.0 - local_t, 6.0) * vol * 0.8
			sample = (sin(phase * f3 * TAU) * 0.4 + randf_range(-1.0, 1.0) * 0.6) * env

		out[i] = clampf(sample, -1.0, 1.0)
	return out


func _gen_impact(p: Dictionary) -> PackedFloat32Array:
	## Low thud + noise burst, configurable noise_mix for different materials
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var freq: float = p["thud_freq"]
	var noise_mix: float = p["noise_mix"]

	for i in count:
		var t: float = float(i) / float(count)
		var phase: float = float(i) / float(SAMPLE_RATE)
		# Sharp attack, moderate decay
		var env: float
		if t < 0.05:
			env = (t / 0.05) * vol  # 5% attack
		else:
			env = pow(1.0 - (t - 0.05) / 0.95, 2.5) * vol
		var tone: float = sin(phase * freq * TAU)
		var noise: float = randf_range(-1.0, 1.0)
		# Low-pass the noise using previous sample
		var prev: float = out[i - 1] if i > 0 else 0.0
		var filtered_noise: float = noise * 0.4 + prev * 0.6
		var sample: float = (tone * (1.0 - noise_mix) + filtered_noise * noise_mix) * env
		out[i] = clampf(sample, -1.0, 1.0)
	return out


func _gen_ricochet(p: Dictionary) -> PackedFloat32Array:
	## Short impact crack → rising frequency ping (classic ricochet whine)
	var impact_dur: float = p["impact_duration"]
	var ping_dur: float = p["ping_duration"]
	var total: float = impact_dur + ping_dur
	var count: int = int(SAMPLE_RATE * total)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var f0: float = p["ping_freq_start"]
	var f1: float = p["ping_freq_end"]
	var noise_mix: float = p["noise_mix"]

	var impact_end: int = int(SAMPLE_RATE * impact_dur)

	for i in count:
		var phase: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		if i < impact_end:
			# Short noise burst — concrete/metal crack
			var t: float = float(i) / float(impact_end)
			var env: float = (1.0 - t) * vol
			sample = randf_range(-1.0, 1.0) * env
		else:
			# Rising ping
			var local_i: int = i - impact_end
			var local_count: int = count - impact_end
			var t: float = float(local_i) / float(local_count)
			var env: float = pow(1.0 - t, 2.0) * vol * 0.6
			var freq: float = lerp(f0, f1, t * t)  # Exponential rise
			var tone: float = sin(phase * freq * TAU)
			var noise: float = randf_range(-1.0, 1.0) * 0.15
			sample = (tone * (1.0 - noise_mix * 0.3) + noise) * env

		out[i] = clampf(sample, -1.0, 1.0)
	return out


## ── Music / Ambient generators ────────────────────────────────────────────

func _gen_drone_loop(p: Dictionary) -> PackedFloat32Array:
	## Seamless loop: layered sine/triangle drones with slow modulation.
	## Crossfades start/end for clean looping.
	var dur: float = p["duration"]
	var count: int = int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(count)
	var vol: float = p["volume"]
	var base_f: float = p["base_freq"]
	var harm_f: float = p["harmonic_freq"]
	var shim_f: float = p["shimmer_freq"]
	var warmth: float = p["warmth"]
	var fade_samples: int = int(SAMPLE_RATE * 0.5)  # 0.5s crossfade

	for i in count:
		var phase: float = float(i) / float(SAMPLE_RATE)
		var t: float = float(i) / float(count)

		# Slow LFO modulation (volume swell)
		var lfo: float = 0.85 + 0.15 * sin(phase * 0.3 * TAU)

		# Base drone — blend sine/triangle based on warmth
		var base_sine: float = sin(phase * base_f * TAU)
		var base_tri: float = 1.0 - 4.0 * absf(fmod(phase * base_f, 1.0) - 0.5)
		var base: float = base_sine * warmth + base_tri * (1.0 - warmth)

		# Harmonic layer
		var harm: float = sin(phase * harm_f * TAU) * 0.4

		# Shimmer — very quiet, slowly pulsing
		var shimmer_lfo: float = 0.5 + 0.5 * sin(phase * 0.15 * TAU)
		var shimmer: float = sin(phase * shim_f * TAU) * 0.15 * shimmer_lfo

		var sample: float = (base * 0.6 + harm + shimmer) * lfo * vol

		# Crossfade edges for seamless looping
		if i < fade_samples:
			sample *= float(i) / float(fade_samples)
		elif i > count - fade_samples:
			sample *= float(count - i) / float(fade_samples)

		out[i] = clampf(sample, -1.0, 1.0)
	return out


## ── Oscillator ────────────────────────────────────────────────────────────

func _oscillate(wave: String, time: float, freq: float) -> float:
	var phase: float = fmod(time * freq, 1.0)
	match wave:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"saw":
			return 2.0 * phase - 1.0
		"triangle":
			return 1.0 - 4.0 * absf(phase - 0.5)
		_:  # sine
			return sin(time * freq * TAU)


## ── WAV Writer ────────────────────────────────────────────────────────────

func _save_wav(path: String, samples: PackedFloat32Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Cannot write: %s" % path)
		return

	var num_samples: int = samples.size()
	var byte_rate: int = SAMPLE_RATE * 2  # 16-bit mono
	var data_size: int = num_samples * 2

	# RIFF header
	file.store_string("RIFF")
	file.store_32(36 + data_size)
	file.store_string("WAVE")

	# fmt chunk
	file.store_string("fmt ")
	file.store_32(16)           # chunk size
	file.store_16(1)            # PCM format
	file.store_16(1)            # mono
	file.store_32(SAMPLE_RATE)  # sample rate
	file.store_32(byte_rate)    # byte rate
	file.store_16(2)            # block align (16-bit mono)
	file.store_16(16)           # bits per sample

	# data chunk
	file.store_string("data")
	file.store_32(data_size)

	for s: float in samples:
		var s16: int = clampi(int(s * 32767.0), -32768, 32767)
		file.store_16(s16)

	file.close()
