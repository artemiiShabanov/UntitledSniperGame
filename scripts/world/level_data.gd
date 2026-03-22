class_name LevelData
extends Resource
## Holds metadata for a single level. Saved as .tres files in res://data/levels/.

@export var level_name: String = "Unnamed"
@export var scene_path: String = ""
@export var run_time_override: float = -1.0  ## Negative = use RunManager default
@export var entry_fee: int = 0  ## Credits deducted on deploy (0 = free)

@export_group("Spawn Variation")
@export var enemy_pool: EnemyPool
@export var enemy_count_range: Vector2i = Vector2i(3, 6)  ## Min/max enemies per run
@export var extraction_count: int = 1  ## How many extraction zones stay active

@export_group("Threat Phases")
@export var early_phase_duration: float = -1.0  ## Negative = use RunManager default
@export var mid_phase_duration: float = -1.0
@export var mid_spawn_interval: float = 15.0  ## Seconds between spawns in MID phase
@export var late_spawn_interval: float = 8.0
@export var mid_max_enemies: int = 6  ## Max concurrent dynamically-spawned enemies
@export var late_max_enemies: int = 12

@export_group("Events")
@export var level_events_pool: Array[LevelEventData] = []
@export var max_events_per_run: int = 1

@export_group("Environment")
@export var available_times_of_day: PackedStringArray = ["day"]
@export var available_weather: PackedStringArray = ["clear"]
