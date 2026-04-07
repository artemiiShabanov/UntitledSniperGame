class_name EnemySpawner
extends Node
## Dynamically spawns enemies during a run based on the threat phase.
## Added as a child of BaseLevel during _ready().

## ── Configuration ──────────────────────────────────────────────────────────

## Phase at which dynamic spawning begins (1-10). Below this = no spawning.
@export var spawn_start_phase: int = 2
## Spawn interval at spawn_start_phase (seconds between spawns)
@export var spawn_interval_initial: float = 20.0
## Spawn interval at phase 10
@export var spawn_interval_final: float = 5.0
## Max concurrent dynamically-spawned enemies at spawn_start_phase
@export var max_enemies_initial: int = 3
## Max concurrent dynamically-spawned enemies at phase 10
@export var max_enemies_final: int = 12

## ── State ──────────────────────────────────────────────────────────────────

var _level: BaseLevel
var _enemy_pool: EnemyPool
var _available_spawns: Array[SpawnPoint] = []
var _spawn_timer: float = 0.0
var _spawned_enemies: Array[Node] = []
var _rng: RandomNumberGenerator
var _used_counts: Dictionary = {}


func setup(level: BaseLevel, pool: EnemyPool, unused_spawns: Array[SpawnPoint]) -> void:
	_level = level
	_enemy_pool = pool
	_available_spawns = unused_spawns
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_spawn_timer = _get_spawn_interval()


func _process(delta: float) -> void:
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Clean up dead/freed enemies from tracking
	_spawned_enemies = _spawned_enemies.filter(func(e) -> bool:
		return is_instance_valid(e) and not e.is_queued_for_deletion()
	)

	var interval := _get_spawn_interval()
	if interval <= 0.0:
		return  # No spawning in this phase

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = interval
		_try_spawn_enemy()


func _get_phase_t() -> float:
	## Returns 0.0-1.0 representing progress from spawn_start_phase to phase 10.
	var phase := RunManager.threat_phase
	if phase < spawn_start_phase:
		return -1.0  # Not spawning yet
	var range_size := RunManager.THREAT_PHASE_MAX - spawn_start_phase
	if range_size <= 0:
		return 1.0
	return clampf(float(phase - spawn_start_phase) / float(range_size), 0.0, 1.0)


func _get_spawn_interval() -> float:
	var t := _get_phase_t()
	if t < 0.0:
		return 0.0  # No spawning
	return lerpf(spawn_interval_initial, spawn_interval_final, t)


func _get_max_enemies() -> int:
	var t := _get_phase_t()
	if t < 0.0:
		return 0
	return int(lerpf(float(max_enemies_initial), float(max_enemies_final), t))


func _try_spawn_enemy() -> void:
	if not _enemy_pool or _available_spawns.is_empty():
		return

	# Check concurrent limit
	var alive_count := _spawned_enemies.size()
	if alive_count >= _get_max_enemies():
		return

	# Pick a spawn point not visible to the player
	var spawn := _pick_hidden_spawn()
	if spawn == null:
		return

	# Pick an enemy type from pool
	var scene := _enemy_pool.pick_random(_rng, _used_counts)
	if scene == null:
		return

	var enemy := scene.instantiate()
	_level.add_child(enemy)
	enemy.global_position = spawn.global_position
	enemy.rotation.y = deg_to_rad(spawn.facing_direction)

	if spawn.behavior_tag != "default" and "initial_behavior" in enemy:
		enemy.initial_behavior = EnemyBase.behavior_from_string(spawn.behavior_tag)
	_spawned_enemies.append(enemy)

	# Track for max_per_run
	var path := scene.resource_path
	_used_counts[path] = _used_counts.get(path, 0) + 1


func _pick_hidden_spawn() -> SpawnPoint:
	## Pick a spawn point that the player can't currently see.
	## Falls back to any spawn if all are visible.
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		return _available_spawns[_rng.randi() % _available_spawns.size()]

	var player: Node3D = player_nodes[0]
	var camera: Camera3D = player.get_viewport().get_camera_3d()
	if not camera:
		return _available_spawns[_rng.randi() % _available_spawns.size()]

	var vp_size := camera.get_viewport().get_visible_rect().size

	# Generate a random starting index and iterate through all spawns
	# (avoids duplicating + shuffling the array every call)
	var count := _available_spawns.size()
	var start := _rng.randi() % count
	var best: SpawnPoint = _available_spawns[start]
	var best_dist := 0.0

	for offset in count:
		var idx := (start + offset) % count
		var spawn: SpawnPoint = _available_spawns[idx]
		var pos := spawn.global_position

		# Track farthest for fallback
		var d := player.global_position.distance_squared_to(pos)
		if d > best_dist:
			best_dist = d
			best = spawn

		# Prefer spawns not on screen
		if camera.is_position_behind(pos):
			return spawn  # Behind camera = not visible
		var screen_pos := camera.unproject_position(pos)
		if screen_pos.x < 0 or screen_pos.x > vp_size.x or screen_pos.y < 0 or screen_pos.y > vp_size.y:
			return spawn

	# Fallback: farthest spawn from the player
	return best
