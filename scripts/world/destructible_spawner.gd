class_name DestructibleSpawner
extends Node
## Spawns destructible targets during level setup.
## Static types (crate, bottle) go at DESTRUCTIBLE spawn points.
## Dynamic types (rat, bird) spawn at random walkable positions.

var _level: BaseLevel
var _pool: DestructiblePool
var _rng: RandomNumberGenerator
var _used_counts: Dictionary = {}


func setup(level: BaseLevel, pool: DestructiblePool) -> void:
	_level = level
	_pool = pool
	_rng = level.rng


func spawn_static(count: int) -> void:
	## Place static destructibles (crate, bottle) at DESTRUCTIBLE spawn points.
	var spawns := _level.get_spawn_points(SpawnPoint.Type.DESTRUCTIBLE)
	if spawns.is_empty():
		return

	# Shuffle spawns
	ArrayUtils.shuffle(spawns, _rng)

	count = mini(count, spawns.size())
	for i in count:
		var scene := _pool.pick_random(_rng, _used_counts, DestructiblePoolEntry.SpawnMode.STATIC)
		if scene == null:
			break

		var target := scene.instantiate()
		_level.add_child(target)
		target.global_position = spawns[i].global_position

		var path := scene.resource_path
		_used_counts[path] = _used_counts.get(path, 0) + 1


func spawn_dynamic(count: int) -> void:
	## Spawn dynamic destructibles (rat, bird) at random ground positions.
	var positions := _find_dynamic_positions(count)

	for pos in positions:
		var scene := _pool.pick_random(_rng, _used_counts, DestructiblePoolEntry.SpawnMode.DYNAMIC)
		if scene == null:
			break

		var target := scene.instantiate()
		_level.add_child(target)
		target.global_position = pos

		var path := scene.resource_path
		_used_counts[path] = _used_counts.get(path, 0) + 1


func _find_dynamic_positions(count: int) -> Array[Vector3]:
	## Find random ground-level positions for dynamic destructibles.
	## Uses enemy spawn points as candidate positions (they're known walkable).
	var result: Array[Vector3] = []

	# Collect all available position sources
	var candidates: Array[Vector3] = []

	# Enemy spawns are good candidates — known to be on walkable ground
	var enemy_spawns := _level.get_spawn_points(SpawnPoint.Type.ENEMY)
	for spawn in enemy_spawns:
		candidates.append(spawn.global_position)

	# Destructible spawns too
	var destr_spawns := _level.get_spawn_points(SpawnPoint.Type.DESTRUCTIBLE)
	for spawn in destr_spawns:
		candidates.append(spawn.global_position)

	if candidates.is_empty():
		return result

	# Pick random positions with slight offset so they don't overlap spawn points
	var used_indices: Array[int] = []
	for _i in count:
		if used_indices.size() >= candidates.size():
			break
		var idx := _rng.randi() % candidates.size()
		var attempts := 0
		while idx in used_indices and attempts < 20:
			idx = _rng.randi() % candidates.size()
			attempts += 1
		if idx in used_indices:
			continue
		used_indices.append(idx)

		# Add small random offset so destructibles aren't right on the spawn marker
		var pos := candidates[idx]
		pos.x += _rng.randf_range(-2.0, 2.0)
		pos.z += _rng.randf_range(-2.0, 2.0)
		result.append(pos)

	return result


