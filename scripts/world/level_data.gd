class_name LevelData
extends Resource
## Holds metadata for a single level. Saved as .tres files in res://data/levels/.

@export var level_name: String = "Unnamed"
@export var scene_path: String = ""
@export var difficulty: int = 1  ## 1-5 scale
@export var run_time_override: float = -1.0  ## Negative = use RunManager default

## Future hooks for Layer 10 — Per-Run Variation
@export var available_times_of_day: PackedStringArray = ["day"]
@export var available_weather: PackedStringArray = ["clear"]
