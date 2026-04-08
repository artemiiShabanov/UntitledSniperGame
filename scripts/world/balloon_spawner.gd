class_name BalloonSpawner
extends Node
## Spawns balloons mid-run based on threat phase changes.
## Balloons appear near living enemies, creating risk/reward tension.
## Higher phases unlock higher-tier balloons.

const BALLOON_SCENE := preload("res://scenes/world/destructibles/destructible_balloon.tscn")

## How often a balloon can spawn (seconds between spawns)
@export var spawn_interval: float = 30.0
## Max concurrent balloons in the air
@export var max_concurrent: int = 2
## Chance a balloon spawns each interval (0-1)
@export var spawn_chance: float = 0.6

var _level: BaseLevel
var _rng: RandomNumberGenerator
var _spawn_timer: float = 0.0
var _active_balloons: Array[Node] = []
var _spawning_enabled: bool = false


func setup(level: BaseLevel) -> void:
	_level = level
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_spawn_timer = spawn_interval * 0.5  # First balloon comes faster

	RunManager.threat_phase_changed.connect(_on_phase_changed)


func _on_phase_changed(phase: int) -> void:
	if DestructibleBalloon.can_spawn_at_phase(phase) and not _spawning_enabled:
		_spawning_enabled = true
		# Spawn one immediately on first eligible phase
		_try_spawn_balloon()


func _process(delta: float) -> void:
	if not _spawning_enabled:
		return
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Clean up destroyed/freed balloons
	_active_balloons = _active_balloons.filter(func(b) -> bool:
		return is_instance_valid(b) and not b.is_queued_for_deletion()
	)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn_balloon()


func _try_spawn_balloon() -> void:
	if _active_balloons.size() >= max_concurrent:
		return
	if _rng.randf() > spawn_chance:
		return

	var pos := _pick_spawn_position()
	if pos == Vector3.INF:
		return

	var phase := RunManager.threat_phase
	var tier := DestructibleBalloon.get_tier_for_phase(phase)

	var balloon: DestructibleBalloon = BALLOON_SCENE.instantiate()
	balloon.tier = tier
	_level.add_child(balloon)
	balloon.global_position = pos

	_active_balloons.append(balloon)

	# Announce to player
	var tier_name: String = ["BRONZE", "SILVER", "GOLD"][tier]
	RunManager.announce_event("%s BALLOON SPOTTED" % tier_name)


func _pick_spawn_position() -> Vector3:
	## Pick a position near a living enemy.
	var enemies := get_tree().get_nodes_in_group("enemy")
	var alive: Array[Node3D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			if "is_dead" in enemy and not enemy.is_dead:
				alive.append(enemy)
			elif "health" in enemy and enemy.health > 0:
				alive.append(enemy)
			else:
				alive.append(enemy)  # Fallback: assume alive if no health field

	if alive.is_empty():
		# Fallback to enemy spawn points
		var spawns := _level.get_spawn_points(SpawnPoint.Type.ENEMY)
		if spawns.is_empty():
			return Vector3.INF
		var spawn: SpawnPoint = spawns[_rng.randi() % spawns.size()]
		var pos := spawn.global_position
		pos.x += _rng.randf_range(-3.0, 3.0)
		pos.z += _rng.randf_range(-3.0, 3.0)
		return pos

	# Pick a random living enemy and offset slightly
	var enemy: Node3D = alive[_rng.randi() % alive.size()]
	var pos := enemy.global_position
	pos.x += _rng.randf_range(-5.0, 5.0)
	pos.z += _rng.randf_range(-5.0, 5.0)
	pos.y = 0.0  # Ground level — balloon rises from there
	return pos
