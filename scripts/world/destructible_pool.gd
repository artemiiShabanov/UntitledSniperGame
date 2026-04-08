class_name DestructiblePool
extends Resource
## Weighted random selection of destructible target scenes.
## Mirrors EnemyPool / NpcPool pattern.

@export var entries: Array[DestructiblePoolEntry] = []


func pick_random(rng: RandomNumberGenerator, used_counts: Dictionary = {}, mode_filter: int = -1) -> PackedScene:
	## Pick a random scene from the pool.
	## mode_filter: -1 = any, 0 = STATIC only, 1 = DYNAMIC only
	var available: Array[DestructiblePoolEntry] = []
	var weights: Array[float] = []

	for entry in entries:
		if entry.scene == null:
			continue
		if mode_filter >= 0 and entry.spawn_mode != mode_filter:
			continue
		if entry.max_per_run >= 0:
			var path := entry.scene.resource_path
			if used_counts.get(path, 0) >= entry.max_per_run:
				continue
		available.append(entry)
		weights.append(entry.weight)

	if available.is_empty():
		return null

	var total_weight := 0.0
	for w in weights:
		total_weight += w

	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for i in available.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return available[i].scene

	return available[-1].scene


func get_entries_by_mode(mode: DestructiblePoolEntry.SpawnMode) -> Array[DestructiblePoolEntry]:
	var result: Array[DestructiblePoolEntry] = []
	for entry in entries:
		if entry.spawn_mode == mode:
			result.append(entry)
	return result
