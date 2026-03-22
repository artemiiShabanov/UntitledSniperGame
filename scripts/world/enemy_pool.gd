class_name EnemyPool
extends Resource

@export var entries: Array[EnemyPoolEntry] = []


func pick_random(rng: RandomNumberGenerator, used_counts: Dictionary = {}) -> PackedScene:
	var available: Array[EnemyPoolEntry] = []
	var weights: Array[float] = []

	for entry in entries:
		if entry.enemy_scene == null:
			continue
		if entry.max_per_run >= 0:
			var path := entry.enemy_scene.resource_path
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
			return available[i].enemy_scene

	return available[-1].enemy_scene
