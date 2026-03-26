class_name AudioBankEntry
extends Resource
## A single sound entry in the AudioBank.
## Maps a StringName ID to an AudioStream with playback metadata.

@export var id: StringName = &""
@export var stream: AudioStream = null
@export var volume_db: float = 0.0
@export var pitch_variance: float = 0.0  ## Random pitch variation (+/-)
@export var bus: StringName = &"SFX"
