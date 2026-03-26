class_name AudioPlaceholder
extends RefCounted
## Generates simple placeholder AudioStreamWAV samples at runtime.
## Used by AudioManager when a bank entry has no real audio file assigned.

const SAMPLE_RATE: int = 22050
const MIX_RATE: int = 22050


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
