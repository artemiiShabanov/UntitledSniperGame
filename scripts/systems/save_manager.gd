extends Node
## Global save manager — autoloaded singleton.
## Handles save/load, multiple slots, and data structure.

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 3
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
	## Returns a lightweight summary for the slot selection screen.
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
		"credits": d.get("credits", 0),
		"xp": d.get("xp", 0),
		"total_extractions": d.get("stats", {}).get("total_extractions", 0),
		"total_deaths": d.get("stats", {}).get("total_deaths", 0),
	}


## ── Data helpers ─────────────────────────────────────────────────────────────

func add_credits(amount: int) -> void:
	data["credits"] = maxi(data.get("credits", 0) + amount, 0)


func add_xp(amount: int) -> void:
	data["xp"] = data.get("xp", 0) + amount
	if amount > 0:
		increment_stat("total_xp_earned", amount)


func get_credits() -> int:
	return data.get("credits", 0)


func get_xp() -> int:
	return data.get("xp", 0)


func get_total_xp_earned() -> int:
	return get_stat("total_xp_earned", 0)


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
	## Only updates the stat if value exceeds the current record.
	var stats: Dictionary = data.get("stats", {})
	if value > stats.get(key, 0):
		stats[key] = value
	data["stats"] = stats


## ── Modifications ───────────────────────────────────────────────────────────

func owns_mod(id: String) -> bool:
	var mods: Dictionary = data.get("modifications", {})
	var owned: Array = mods.get("owned", [])
	return id in owned


func purchase_mod(id: String, cost: int) -> bool:
	if owns_mod(id) or get_credits() < cost:
		return false
	add_credits(-cost)
	var mods: Dictionary = data.get("modifications", {})
	var owned: Array = mods.get("owned", [])
	owned.append(id)
	mods["owned"] = owned
	data["modifications"] = mods
	save()
	return true


func equip_mod(id: String) -> void:
	if not owns_mod(id):
		return
	var mod: RifleMod = ModRegistry.get_mod(id)
	if not mod:
		return
	var mods: Dictionary = data.get("modifications", {})
	var equipped: Dictionary = mods.get("equipped", {})
	equipped[mod.slot] = id
	mods["equipped"] = equipped
	data["modifications"] = mods
	save()


func get_equipped_mod(slot: String) -> String:
	var mods: Dictionary = data.get("modifications", {})
	var equipped: Dictionary = mods.get("equipped", {})
	return equipped.get(slot, slot + "_standard")


func get_equipped_loadout() -> Dictionary:
	var mods: Dictionary = data.get("modifications", {})
	return mods.get("equipped", {}).duplicate()


## ── Skills ──────────────────────────────────────────────────────────────────

func has_skill(id: String) -> bool:
	var skills: Array = data.get("skills", [])
	return id in skills


func purchase_skill(id: String, xp_cost: int) -> bool:
	if has_skill(id) or get_xp() < xp_cost:
		return false
	add_xp(-xp_cost)
	var skills: Array = data.get("skills", [])
	skills.append(id)
	data["skills"] = skills
	save()
	return true


func get_owned_skills() -> Array:
	return data.get("skills", [])


func has_skill_effect(effect_key: String) -> bool:
	## Check if any owned skill provides the given effect.
	for skill_id in get_owned_skills():
		var skill: PlayerSkill = SkillRegistry.get_skill(skill_id)
		if skill and skill.effect_key == effect_key:
			return true
	return false


func get_skill_stat_bonus(stat_key: String, default: float = 0.0) -> float:
	## Sum all skill bonuses for a given stat key.
	var total := 0.0
	for skill_id in get_owned_skills():
		var skill: PlayerSkill = SkillRegistry.get_skill(skill_id)
		if skill and skill.stat_bonus.has(stat_key):
			total += skill.stat_bonus[stat_key]
	if total == 0.0:
		return default
	return total


## ── Run stats aggregation ───────────────────────────────────────────────────

func commit_run_stats(run_stats: Dictionary, level_path: String, success: bool) -> void:
	## Called at end of every run. Aggregates per-run stats into lifetime
	## totals, best records, and per-level stats.

	# Lifetime totals
	increment_stat("total_kills", run_stats.get("kills", 0))
	increment_stat("total_headshots", run_stats.get("headshots", 0))
	increment_stat("total_shots_fired", run_stats.get("shots_fired", 0))
	increment_stat("total_shots_hit", run_stats.get("shots_hit", 0))
	increment_stat("total_runs", 1)

	# Best records (only update if new value is higher)
	update_stat_max("best_survival_time", run_stats.get("time_survived", 0.0))
	update_stat_max("best_credits_one_run", run_stats.get("credits_earned", 0))
	update_stat_max("best_kills_one_run", run_stats.get("kills", 0))
	update_stat_max("longest_kill_distance", run_stats.get("longest_kill_distance", 0.0))

	# Per-level stats
	if level_path != "":
		var per_level: Dictionary = data.get("per_level_stats", {})
		if not per_level.has(level_path):
			per_level[level_path] = {
				"runs": 0,
				"extractions": 0,
				"deaths": 0,
				"total_kills": 0,
				"best_time": 0.0,
				"best_credits": 0,
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
		if run_stats.get("credits_earned", 0) > ls.get("best_credits", 0):
			ls["best_credits"] = run_stats.get("credits_earned", 0)
		per_level[level_path] = ls
		data["per_level_stats"] = per_level


func get_accuracy_percent() -> float:
	## Returns overall accuracy as 0.0 to 100.0.
	var fired: int = get_stat("total_shots_fired", 0)
	if fired == 0:
		return 0.0
	return float(get_stat("total_shots_hit", 0)) / float(fired) * 100.0


func get_headshot_percent() -> float:
	## Returns headshot percentage as 0.0 to 100.0.
	var kills: int = get_stat("total_kills", 0)
	if kills == 0:
		return 0.0
	return float(get_stat("total_headshots", 0)) / float(kills) * 100.0


func get_level_stats(level_path: String) -> Dictionary:
	## Returns per-level stats dict, or empty dict if no data.
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
		"credits": 0,
		"xp": 0,
		"ammo_inventory": {},
		"modifications": {
			"owned": [
				"barrel_standard", "stock_standard", "bolt_standard",
				"magazine_standard", "scope_standard",
			],
			"equipped": {
				"barrel": "barrel_standard",
				"stock": "stock_standard",
				"bolt": "bolt_standard",
				"magazine": "magazine_standard",
				"scope": "scope_standard",
			},
		},
		"skills": [],
		"cosmetics": [],
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
			"best_credits_one_run": 0,
			"best_kills_one_run": 0,
			"longest_kill_distance": 0.0,
		},
		"per_level_stats": {},
	}


func _migrate(save_data: Dictionary) -> Dictionary:
	## Upgrades save format when version changes.
	## Add migration steps here as SAVE_VERSION increments.
	var ver: int = save_data.get("version", 0)

	if ver < 2:
		# v1 → v2: replace "upgrades" array with "modifications" dict
		save_data.erase("upgrades")
		if not save_data.has("modifications"):
			save_data["modifications"] = {
				"owned": [
					"barrel_standard", "stock_standard", "bolt_standard",
					"magazine_standard", "scope_standard",
				],
				"equipped": {
					"barrel": "barrel_standard",
					"stock": "stock_standard",
					"bolt": "bolt_standard",
					"magazine": "magazine_standard",
					"scope": "scope_standard",
				},
			}

	if ver < 3:
		# v2 → v3: add total_xp_earned stat (reconstruct from current XP + spent on skills)
		var stats: Dictionary = save_data.get("stats", {})
		if not stats.has("total_xp_earned"):
			var current_xp: int = save_data.get("xp", 0)
			var spent_xp: int = 0
			for skill_id in save_data.get("skills", []):
				var skill: PlayerSkill = SkillRegistry.get_skill(skill_id)
				if skill:
					spent_xp += skill.cost
			stats["total_xp_earned"] = current_xp + spent_xp
			save_data["stats"] = stats

	save_data["version"] = SAVE_VERSION
	return save_data
