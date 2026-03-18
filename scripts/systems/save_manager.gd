extends Node
## Global save manager — autoloaded singleton.
## Handles save/load, multiple slots, and data structure.

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1
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


func get_credits() -> int:
	return data.get("credits", 0)


func get_xp() -> int:
	return data.get("xp", 0)


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
		"upgrades": [],
		"skills": [],
		"cosmetics": [],
		"stats": {
			"total_kills": 0,
			"total_extractions": 0,
			"total_deaths": 0,
			"accuracy_shots_fired": 0,
			"accuracy_shots_hit": 0,
			"headshots": 0,
			"longest_survival": 0.0,
			"most_credits_one_run": 0,
		},
		"per_level_stats": {},
	}


func _migrate(save_data: Dictionary) -> Dictionary:
	## Upgrades save format when version changes.
	## Add migration steps here as SAVE_VERSION increments.
	var ver: int = save_data.get("version", 0)

	if ver < 1:
		# Future: migrate from v0 to v1
		pass

	save_data["version"] = SAVE_VERSION
	return save_data
