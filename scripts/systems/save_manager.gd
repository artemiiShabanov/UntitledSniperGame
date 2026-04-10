extends Node
## Global save manager — autoloaded singleton.
## Handles save/load, multiple slots, and data structure.

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 5
const MAX_SLOTS := 3

## Currently loaded save data. Empty dict means no save loaded.
var data: Dictionary = {}
var current_slot: int = -1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## ── Public API ───────────────────────────────────────────────────────────────

func new_game(slot: int) -> void:
	current_slot = slot
	data = _default_data(slot)
	_write_to_disk()


func save() -> void:
	if current_slot < 0:
		push_warning("SaveManager: no slot selected, cannot save.")
		return
	_write_to_disk()


func load_slot(slot: int) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("SaveManager: slot %d does not exist." % slot)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: failed to open %s" % path)
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("SaveManager: JSON parse error in slot %d — %s" % [slot, json.get_error_message()])
		return false

	data = json.data as Dictionary
	current_slot = slot
	data = _migrate(data)
	return true


func delete_slot(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if current_slot == slot:
		data = {}
		current_slot = -1


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func get_slot_summary(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var d: Dictionary = json.data
	return {
		"slot": slot,
		"xp": d.get("xp", 0),
		"total_extractions": d.get("stats", {}).get("total_extractions", 0),
		"total_deaths": d.get("stats", {}).get("total_deaths", 0),
	}


## ── XP ──────────────────────────────────────────────────────────────────────

func add_xp(amount: int) -> void:
	data["xp"] = data.get("xp", 0) + amount
	if amount > 0:
		increment_stat("total_xp_earned", amount)


func get_xp() -> int:
	return data.get("xp", 0)


func get_total_xp_earned() -> int:
	return get_stat("total_xp_earned", 0)


## ── Stats ───────────────────────────────────────────────────────────────────

func update_stat(key: String, value: Variant) -> void:
	var stats: Dictionary = data.get("stats", {})
	stats[key] = value
	data["stats"] = stats


func increment_stat(key: String, amount: int = 1) -> void:
	var stats: Dictionary = data.get("stats", {})
	stats[key] = stats.get(key, 0) + amount
	data["stats"] = stats


func get_stat(key: String, default: Variant = 0) -> Variant:
	return data.get("stats", {}).get(key, default)


func update_stat_max(key: String, value: Variant) -> void:
	var stats: Dictionary = data.get("stats", {})
	if value > stats.get(key, 0):
		stats[key] = value
	data["stats"] = stats


## ── Mod Inventory ──────────────────────────────────────────────────────────

func get_mod_inventory() -> Array:
	return data.get("mod_inventory", [])


func get_mods_for_slot(slot_name: String) -> Array:
	## Returns [{index: int, mod_data: Dictionary}] for mods matching the given slot.
	var result: Array = []
	var inv: Array = get_mod_inventory()
	for i in range(inv.size()):
		var mod_data: Dictionary = inv[i]
		var s: int = mod_data.get("slot", 0)
		if s >= 0 and s < RifleMod.SLOT_NAMES.size() and RifleMod.SLOT_NAMES[s] == slot_name:
			result.append({"index": i, "mod_data": mod_data})
	return result


func get_mod_at(index: int) -> Dictionary:
	var inv: Array = get_mod_inventory()
	if index < 0 or index >= inv.size():
		return {}
	return inv[index]


func add_mod_to_inventory(mod: RifleMod) -> bool:
	## Adds a mod to inventory. Returns false if slot is full (5 per slot cap).
	var inv: Array = data.get("mod_inventory", [])
	var slot_name := mod.get_slot_name()
	var count := 0
	for entry: Dictionary in inv:
		if RifleMod.SLOT_NAMES[entry.get("slot", 0)] == slot_name:
			count += 1
	if count >= 5:
		return false
	inv.append(mod.serialize())
	data["mod_inventory"] = inv
	return true


func remove_mod_from_inventory(index: int) -> void:
	var inv: Array = data.get("mod_inventory", [])
	if index < 0 or index >= inv.size():
		return
	# Unequip if equipped
	var equipped: Dictionary = data.get("equipped_mods", {})
	for slot_name: String in equipped:
		if equipped[slot_name] == index:
			equipped.erase(slot_name)
		elif equipped[slot_name] > index:
			equipped[slot_name] = equipped[slot_name] - 1
	data["equipped_mods"] = equipped
	inv.remove_at(index)
	data["mod_inventory"] = inv


func equip_mod(index: int) -> void:
	var mod_data := get_mod_at(index)
	if mod_data.is_empty():
		return
	var slot_name: String = RifleMod.SLOT_NAMES[mod_data.get("slot", 0)]
	var equipped: Dictionary = data.get("equipped_mods", {})
	equipped[slot_name] = index
	data["equipped_mods"] = equipped
	save()


func unequip_mod(slot_name: String) -> void:
	var equipped: Dictionary = data.get("equipped_mods", {})
	equipped.erase(slot_name)
	data["equipped_mods"] = equipped
	save()


func get_equipped_loadout() -> Dictionary:
	## Returns { slot_name: inventory_index } for all equipped mods.
	return data.get("equipped_mods", {}).duplicate()


func strip_equipped_mods() -> void:
	## Called on run failure — removes all equipped mods from inventory.
	var equipped: Dictionary = data.get("equipped_mods", {})
	# Collect indices in descending order to remove safely.
	var indices: Array[int] = []
	for slot_name: String in equipped:
		indices.append(equipped[slot_name])
	indices.sort()
	indices.reverse()
	for idx in indices:
		var inv: Array = data.get("mod_inventory", [])
		if idx >= 0 and idx < inv.size():
			inv.remove_at(idx)
	data["mod_inventory"] = data.get("mod_inventory", [])
	data["equipped_mods"] = {}


func tick_mod_durability() -> void:
	## Called on successful extraction. Decrements durability of equipped mods.
	## Removes depleted mods.
	var equipped: Dictionary = data.get("equipped_mods", {})
	var inv: Array = data.get("mod_inventory", [])
	var to_remove: Array[int] = []
	for slot_name: String in equipped:
		var idx: int = equipped[slot_name]
		if idx < 0 or idx >= inv.size():
			continue
		var mod_data: Dictionary = inv[idx]
		mod_data["durability"] = mod_data.get("durability", 1) - 1
		inv[idx] = mod_data
		if mod_data["durability"] <= 0:
			to_remove.append(idx)

	# Remove depleted mods (descending order)
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		remove_mod_from_inventory(idx)

	data["mod_inventory"] = data.get("mod_inventory", [])


## ── Skills (Tiered) ────────────────────────────────────────────────────────

func get_skill_tier(skill_id: String) -> int:
	## Returns current tier (0 = not purchased).
	var tiers: Dictionary = data.get("skill_tiers", {})
	return tiers.get(skill_id, 0)


func purchase_skill_tier(skill_id: String) -> bool:
	## Purchases the next tier. Returns false if max tier or not enough XP.
	var skill: PlayerSkill = SkillRegistry.get_skill(skill_id)
	if not skill:
		return false
	var current_tier := get_skill_tier(skill_id)
	var next_tier := current_tier + 1
	if next_tier > skill.get_max_tier():
		return false
	var cost := skill.get_tier_cost(next_tier)
	if get_xp() < cost:
		return false
	add_xp(-cost)
	var tiers: Dictionary = data.get("skill_tiers", {})
	tiers[skill_id] = next_tier
	data["skill_tiers"] = tiers
	save()
	return true


func get_skill_stat_bonus(stat_key: String, default: float = 0.0) -> float:
	## Sum all skill bonuses for a given stat key across all purchased tiers.
	var total := 0.0
	var tiers: Dictionary = data.get("skill_tiers", {})
	for skill_id: String in tiers:
		var tier: int = tiers[skill_id]
		if tier <= 0:
			continue
		var skill: PlayerSkill = SkillRegistry.get_skill(skill_id)
		if not skill:
			continue
		var bonus: Dictionary = skill.get_tier_stat_bonus(tier)
		if bonus.has(stat_key):
			total += bonus[stat_key]
	if total == 0.0:
		return default
	return total


## ── Army Upgrades ──────────────────────────────────────────────────────────

func is_army_upgrade_unlocked(id: String) -> bool:
	var unlocked: Array = data.get("army_upgrades_unlocked", [])
	return id in unlocked


func unlock_army_upgrade(id: String) -> void:
	var unlocked: Array = data.get("army_upgrades_unlocked", [])
	if id not in unlocked:
		unlocked.append(id)
		data["army_upgrades_unlocked"] = unlocked
		save()


## ── Opportunities ──────────────────────────────────────────────────────────

func get_opportunity_completions(opp_id: String) -> int:
	var completions: Dictionary = data.get("opportunity_completions", {})
	return completions.get(opp_id, 0)


func record_opportunity_completion(opp_id: String) -> void:
	var completions: Dictionary = data.get("opportunity_completions", {})
	completions[opp_id] = completions.get(opp_id, 0) + 1
	data["opportunity_completions"] = completions


## ── Palette Unlocks ────────────────────────────────────────────────────────

func get_unlocked_palettes() -> Array:
	return data.get("unlocked_palettes", ["tactical"])


func has_palette(palette_name: String) -> bool:
	return palette_name in get_unlocked_palettes()


func unlock_palette(palette_name: String) -> void:
	var unlocked: Array = data.get("unlocked_palettes", ["tactical"])
	if palette_name not in unlocked:
		unlocked.append(palette_name)
		data["unlocked_palettes"] = unlocked
		save()


func check_and_unlock_palettes() -> Array[String]:
	var newly_unlocked: Array[String] = []
	var stats: Dictionary = data.get("stats", {})

	if not has_palette("midnight"):
		if stats.get("total_extractions", 0) >= 5:
			unlock_palette("midnight")
			newly_unlocked.append("midnight")

	if not has_palette("noir"):
		if stats.get("total_kills", 0) >= 50:
			unlock_palette("noir")
			newly_unlocked.append("noir")

	return newly_unlocked


## ── Run stats aggregation ───────────────────────────────────────────────────

func commit_run_stats(run_stats: Dictionary, level_path: String, success: bool) -> void:
	increment_stat("total_kills", run_stats.get("kills", 0))
	increment_stat("total_headshots", run_stats.get("headshots", 0))
	increment_stat("total_shots_fired", run_stats.get("shots_fired", 0))
	increment_stat("total_shots_hit", run_stats.get("shots_hit", 0))
	increment_stat("total_runs", 1)

	update_stat_max("best_survival_time", run_stats.get("time_survived", 0.0))
	update_stat_max("best_score_one_run", run_stats.get("score_earned", 0))
	update_stat_max("best_kills_one_run", run_stats.get("kills", 0))
	update_stat_max("longest_kill_distance", run_stats.get("longest_kill_distance", 0.0))

	if level_path != "":
		var per_level: Dictionary = data.get("per_level_stats", {})
		if not per_level.has(level_path):
			per_level[level_path] = {
				"runs": 0, "extractions": 0, "deaths": 0,
				"total_kills": 0, "best_time": 0.0, "best_score": 0,
			}
		var ls: Dictionary = per_level[level_path]
		ls["runs"] = ls.get("runs", 0) + 1
		if success:
			ls["extractions"] = ls.get("extractions", 0) + 1
		else:
			ls["deaths"] = ls.get("deaths", 0) + 1
		ls["total_kills"] = ls.get("total_kills", 0) + run_stats.get("kills", 0)
		if run_stats.get("time_survived", 0.0) > ls.get("best_time", 0.0):
			ls["best_time"] = run_stats.get("time_survived", 0.0)
		if run_stats.get("score_earned", 0) > ls.get("best_score", 0):
			ls["best_score"] = run_stats.get("score_earned", 0)
		per_level[level_path] = ls
		data["per_level_stats"] = per_level


func get_accuracy_percent() -> float:
	var fired: int = get_stat("total_shots_fired", 0)
	if fired == 0:
		return 0.0
	return float(get_stat("total_shots_hit", 0)) / float(fired) * 100.0


func get_headshot_percent() -> float:
	var kills: int = get_stat("total_kills", 0)
	if kills == 0:
		return 0.0
	return float(get_stat("total_headshots", 0)) / float(kills) * 100.0


func get_level_stats(level_path: String) -> Dictionary:
	return data.get("per_level_stats", {}).get(level_path, {})


## ── Internal ─────────────────────────────────────────────────────────────────

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d.json" % slot


func _write_to_disk() -> void:
	var path := _slot_path(current_slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: cannot write to %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _default_data(slot: int) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"slot": slot,
		"xp": 0,
		"mod_inventory": [],
		"equipped_mods": {},
		"skill_tiers": {},
		"army_upgrades_unlocked": [],
		"opportunity_completions": {},
		"unlocked_palettes": ["tactical"],
		"stats": {
			"total_runs": 0,
			"total_kills": 0,
			"total_headshots": 0,
			"total_extractions": 0,
			"total_deaths": 0,
			"total_shots_fired": 0,
			"total_shots_hit": 0,
			"total_xp_earned": 0,
			"best_survival_time": 0.0,
			"best_score_one_run": 0,
			"best_kills_one_run": 0,
			"longest_kill_distance": 0.0,
		},
		"per_level_stats": {},
	}


func _migrate(save_data: Dictionary) -> Dictionary:
	var ver: int = save_data.get("version", 0)

	if ver < 2:
		save_data.erase("upgrades")
		if not save_data.has("modifications"):
			save_data["modifications"] = {
				"owned": [], "equipped": {},
			}

	if ver < 3:
		var stats: Dictionary = save_data.get("stats", {})
		if not stats.has("total_xp_earned"):
			stats["total_xp_earned"] = save_data.get("xp", 0)
			save_data["stats"] = stats

	if ver < 4:
		save_data.erase("cosmetics")
		if not save_data.has("unlocked_palettes"):
			save_data["unlocked_palettes"] = ["tactical"]

	if ver < 5:
		# v4 → v5: Medieval pivot — new data schema
		save_data.erase("credits")
		save_data.erase("ammo_inventory")
		save_data.erase("modifications")
		save_data.erase("skills")
		if not save_data.has("mod_inventory"):
			save_data["mod_inventory"] = []
		if not save_data.has("equipped_mods"):
			save_data["equipped_mods"] = {}
		if not save_data.has("skill_tiers"):
			save_data["skill_tiers"] = {}
		if not save_data.has("army_upgrades_unlocked"):
			save_data["army_upgrades_unlocked"] = []
		if not save_data.has("opportunity_completions"):
			save_data["opportunity_completions"] = {}
		# Rename best_credits_one_run → best_score_one_run
		var stats: Dictionary = save_data.get("stats", {})
		if stats.has("best_credits_one_run"):
			stats["best_score_one_run"] = stats.get("best_credits_one_run", 0)
			stats.erase("best_credits_one_run")
			save_data["stats"] = stats

	save_data["version"] = SAVE_VERSION
	return save_data
