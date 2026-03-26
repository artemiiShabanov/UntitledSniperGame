@tool
extends EditorScript
## UI Sound Generator — run from Editor > Run Script (Ctrl+Shift+X)
## Generates sfxr-style WAV files for all UI audio banks.
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
