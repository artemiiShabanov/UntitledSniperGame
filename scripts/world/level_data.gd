class_name LevelData
extends Resource
## Holds metadata for a single level. Saved as .tres files in res://data/levels/.

@export var level_name: String = "Unnamed"
@export var scene_path: String = ""
@export var run_time_override: float = -1.0  ## Negative = use RunManager default
@export var entry_fee: int = 0  ## Credits deducted on deploy (0 = free)
@export var unlock_extractions: int = 0  ## Total extractions needed to unlock (0 = always open)
@export var unlock_xp: int = 0  ## Total XP earned needed to unlock (0 = no requirement)


func is_unlocked() -> bool:
	if unlock_extractions > 0:
		if SaveManager.get_stat("total_extractions", 0) < unlock_extractions:
			return false
	if unlock_xp > 0:
		if SaveManager.get_xp() < unlock_xp:
			return false
	return true


func get_unlock_requirements_text() -> String:
	var parts: Array[String] = []
	if unlock_extractions > 0:
		parts.append("%d extractions" % unlock_extractions)
	if unlock_xp > 0:
		parts.append("%d XP" % unlock_xp)
	return " + ".join(parts)


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
