class_name LevelData
extends Resource
## Holds metadata for a single level. Saved as .tres files in res://data/levels/.
## Simplified for medieval pivot — no NPC pool, no ammo, no contracts, no entry fee.

@export var level_name: String = "Unnamed"
@export var scene_path: String = ""

@export_group("Castle")
@export var castle_hp: int = 100  ## Starting castle HP for this level

@export_group("Spawn Variation")
@export var extraction_count: int = 3  ## How many extraction zones available

@export_group("Audio")
@export var level_ambient: AudioStream  ## Per-level ambient soundscape
@export var level_theme: AudioStream    ## Per-level music bed

@export_group("Environment")
@export var available_times_of_day: PackedStringArray = ["day"]
@export var available_weather: PackedStringArray = ["clear"]
