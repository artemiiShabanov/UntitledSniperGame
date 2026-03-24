class_name NpcPool
extends Resource
## Weighted random selection of NPC scenes. Mirrors EnemyPool.

@export var entries: Array[NpcPoolEntry] = []


func pick_random(rng: RandomNumberGenerator, used_counts: Dictionary = {}) -> PackedScene:
	var available: Array[NpcPoolEntry] = []
	var weights: Array[float] = []

	for entry in entries:
		if entry.npc_scene == null:
			continue
		if entry.max_per_run >= 0:
			var path := entry.npc_scene.resource_path
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
			return available[i].npc_scene

	return available[-1].npc_scene
