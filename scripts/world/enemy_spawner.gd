class_name EnemySpawner
extends Node
## Dynamically spawns enemies during a run based on the threat phase.
## Added as a child of BaseLevel during _ready().

## ── Configuration ──────────────────────────────────────────────────────────

## Spawn intervals per phase (seconds between spawns). 0 = no spawning.
@export var early_spawn_interval: float = 0.0
@export var mid_spawn_interval: float = 15.0
@export var late_spawn_interval: float = 8.0

## Max concurrent dynamically-spawned enemies per phase
@export var early_max_enemies: int = 0
@export var mid_max_enemies: int = 6
@export var late_max_enemies: int = 12

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
	_spawned_enemies = _spawned_enemies.filter(func(e: Node) -> bool:
		return is_instance_valid(e) and not e.is_queued_for_deletion()
	)

	var interval := _get_spawn_interval()
	if interval <= 0.0:
		return  # No spawning in this phase

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = interval
		_try_spawn_enemy()


func _get_spawn_interval() -> float:
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			return early_spawn_interval
		RunManager.ThreatPhase.MID:
			return mid_spawn_interval
		RunManager.ThreatPhase.LATE:
			return late_spawn_interval
	return 0.0


func _get_max_enemies() -> int:
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			return early_max_enemies
		RunManager.ThreatPhase.MID:
			return mid_max_enemies
		RunManager.ThreatPhase.LATE:
			return late_max_enemies
	return 0


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
	enemy.global_position = spawn.global_position
	enemy.rotation.y = deg_to_rad(spawn.facing_direction)

	if spawn.behavior_tag != "default" and "initial_behavior" in enemy:
		enemy.initial_behavior = spawn.behavior_tag

	_level.add_child(enemy)
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

	# Shuffle spawns
	var shuffled := _available_spawns.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: SpawnPoint = shuffled[j]
		shuffled[j] = shuffled[i]
		shuffled[i] = tmp

	# Prefer spawns not on screen (check if point is behind camera or outside frustum)
	for spawn in shuffled:
		if not camera.is_position_behind(spawn.global_position):
			var screen_pos := camera.unproject_position(spawn.global_position)
			var vp_size := camera.get_viewport().get_visible_rect().size
			if screen_pos.x < 0 or screen_pos.x > vp_size.x or screen_pos.y < 0 or screen_pos.y > vp_size.y:
				return spawn
		else:
			# Behind camera = not visible, good spawn
			return spawn

	# Fallback: pick the farthest spawn from the player
	var best: SpawnPoint = shuffled[0]
	var best_dist := 0.0
	for spawn in shuffled:
		var d := player.global_position.distance_squared_to(spawn.global_position)
		if d > best_dist:
			best_dist = d
			best = spawn
	return best
