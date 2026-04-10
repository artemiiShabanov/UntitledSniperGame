extends Node
## Mod Generator — autoloaded singleton (was ModRegistry).
## Generates procedural rifle mods from rarity + slot using budget allocation.

const SLOTS := RifleMod.SLOT_NAMES


func generate(slot: RifleMod.Slot, rarity: RifleMod.Rarity) -> RifleMod:
	## Generates a single procedural mod for the given slot and rarity.
	var mod := RifleMod.new()
	mod.slot = slot
	mod.rarity = rarity
	mod.stat_budget = RifleMod.RARITY_BUDGETS[rarity]
	mod.max_durability = RifleMod.RARITY_DURABILITY[rarity]
	mod.durability = mod.max_durability
	mod.visual_type = randi_range(1, 3)
	mod.stats = _roll_stats(slot, mod.stat_budget)
	return mod


func generate_choices(score: int, phase: int, count: int = 3) -> Array[RifleMod]:
	## Generates mod choices for post-extraction reward screen.
	## Each choice gets a random slot and a rarity drawn from a weighted pool.
	var choices: Array[RifleMod] = []
	var rarity_weights := _calc_rarity_weights(score, phase)
	for i in range(count):
		var rarity := _pick_weighted_rarity(rarity_weights)
		var slot := randi_range(0, RifleMod.Slot.SCOPE) as RifleMod.Slot
		choices.append(generate(slot, rarity))
	return choices


func _roll_stats(slot: RifleMod.Slot, budget: int) -> Dictionary:
	var table: Dictionary = RifleMod.SLOT_STAT_TABLES[slot]
	var stats := {}
	var remaining := budget

	# Separate boolean and range stats.
	var boolean_keys: Array[String] = []
	var range_keys: Array[String] = []
	for key: String in table:
		var entry: Array = table[key]
		if entry.size() == 1:
			boolean_keys.append(key)
		else:
			range_keys.append(key)

	# Roll boolean stats first — each has a fixed cost.
	for key in boolean_keys:
		var cost: int = int(table[key][0])
		if remaining >= cost and randf() < _boolean_chance(budget, cost):
			stats[key] = true
			remaining -= cost

	# Distribute remaining budget across range stats.
	if range_keys.size() > 0 and remaining > 0:
		# Generate random weights for each stat.
		var weights: Array[float] = []
		var total_weight := 0.0
		for key in range_keys:
			var w := randf_range(0.2, 1.0)
			weights.append(w)
			total_weight += w

		# Allocate budget proportionally and lerp within [min, max].
		for i in range(range_keys.size()):
			var key: String = range_keys[i]
			var entry: Array = table[key]
			var min_val: float = entry[0]
			var max_val: float = entry[1]
			var share := weights[i] / total_weight
			# t ranges 0-1 based on budget share relative to max possible.
			var max_budget := float(RifleMod.RARITY_BUDGETS[RifleMod.Rarity.EPIC])
			var allocated := share * float(remaining)
			var t := clampf(allocated / (max_budget * share), 0.0, 1.0)
			stats[key] = lerpf(min_val, max_val, t)

	return stats


func _boolean_chance(total_budget: int, cost: int) -> float:
	## Higher budget relative to cost = higher chance of purchasing the boolean.
	## At minimum budget to afford it: ~30% chance. At epic budget: ~80% chance.
	var ratio := float(total_budget) / float(cost)
	return clampf(ratio * 0.2, 0.1, 0.8)


func _calc_rarity_weights(score: int, phase: int) -> Array[float]:
	## Returns [common, uncommon, rare, epic] weights based on score and phase.
	## Early runs favor common; high score + late phase favors rare/epic.
	var power := (float(score) / 500.0) + (float(phase) / 20.0)
	power = clampf(power, 0.0, 3.0)
	return [
		maxf(1.0 - power * 0.3, 0.05),       # common
		clampf(0.5 + power * 0.1, 0.1, 0.5), # uncommon
		clampf(power * 0.2 - 0.1, 0.0, 0.4), # rare
		clampf(power * 0.1 - 0.2, 0.0, 0.2), # epic
	]


func _pick_weighted_rarity(weights: Array[float]) -> RifleMod.Rarity:
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var cumulative := 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return i as RifleMod.Rarity
	return RifleMod.Rarity.COMMON
