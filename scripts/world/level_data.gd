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
		if SaveManager.get_total_xp_earned() < unlock_xp:
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

@export_group("Enemy Spawning")
@export var spawn_start_phase: int = 2  ## Phase at which dynamic spawning begins (1-10)
@export var spawn_interval_initial: float = 20.0  ## Seconds between spawns at start phase
@export var spawn_interval_final: float = 5.0  ## Seconds between spawns at phase 10
@export var max_enemies_initial: int = 3  ## Max concurrent enemies at start phase
@export var max_enemies_final: int = 12  ## Max concurrent enemies at phase 10

@export_group("NPC Population")
@export var npc_pool: NpcPool
@export var npc_count_range: Vector2i = Vector2i(3, 6)  ## Min/max NPCs spawned at level start

@export_group("Destructibles")
@export var destructible_pool: DestructiblePool
@export var static_destructible_count_range: Vector2i = Vector2i(4, 8)  ## Crates/bottles placed at spawn points
@export var dynamic_destructible_count: int = 3  ## Rats/birds spawned at random positions
@export var balloon_spawn_interval: float = 30.0  ## Seconds between balloon spawn attempts
@export var balloon_max_concurrent: int = 2  ## Max balloons in the air at once
@export var balloon_spawn_chance: float = 0.6  ## Chance per interval (0-1)

@export_group("Audio")
@export var level_ambient: AudioStream  ## Per-level ambient soundscape
@export var level_theme: AudioStream    ## Per-level music bed

@export_group("Environment")
@export var available_times_of_day: PackedStringArray = ["day"]
@export var available_weather: PackedStringArray = ["clear"]
