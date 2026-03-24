extends Node
## Mod Registry — autoloaded singleton.
## Central catalog of all rifle modifications.

const SLOTS := ["barrel", "stock", "bolt", "magazine", "scope"]

var _mods: Dictionary = {}  ## { id: RifleMod }


func _ready() -> void:
	_register_all()


func get_mod(id: String) -> RifleMod:
	return _mods.get(id, null)


func get_mods_for_slot(slot: String) -> Array[RifleMod]:
	var result: Array[RifleMod] = []
	for mod: RifleMod in _mods.values():
		if mod.slot == slot:
			result.append(mod)
	return result


func get_default_mod(slot: String) -> RifleMod:
	return _mods.get(slot + "_standard", null)


## ── Mod Definitions ─────────────────────────────────────────────────────────

func _register_all() -> void:
	# ── Barrel ────────────────────────────────────────────────────────────
	_add(RifleMod.create(
		"barrel_standard", "Standard Barrel", "barrel", 0,
		"Balanced barrel. No surprises.",
		{"muzzle_velocity": 300.0, "bullet_gravity": 9.8}
	))
	_add(RifleMod.create(
		"barrel_long", "Long Barrel", "barrel", 300,
		"Extended barrel for higher muzzle velocity. Less bullet drop at range.",
		{"muzzle_velocity": 420.0, "bullet_gravity": 9.8}
	))

	# ── Stock ─────────────────────────────────────────────────────────────
	_add(RifleMod.create(
		"stock_standard", "Standard Stock", "stock", 0,
		"Basic stock. Gets the job done.",
		{"sway_amplitude": 0.003, "breath_max": 3.0}
	))

	# ── Bolt ──────────────────────────────────────────────────────────────
	_add(RifleMod.create(
		"bolt_standard", "Standard Bolt", "bolt", 0,
		"Factory bolt action. Reliable.",
		{"bolt_cycle_time": 1.2, "reload_time": 2.5}
	))

	# ── Magazine ──────────────────────────────────────────────────────────
	_add(RifleMod.create(
		"magazine_standard", "Standard Mag", "magazine", 0,
		"5-round internal magazine.",
		{"magazine_size": 5}
	))
	_add(RifleMod.create(
		"magazine_extended", "Extended Mag", "magazine", 300,
		"Detachable box magazine. Holds 8 rounds.",
		{"magazine_size": 8}
	))

	# ── Scope ─────────────────────────────────────────────────────────────
	_add(RifleMod.create(
		"scope_standard", "Iron Sights", "scope", 0,
		"Open sights. Wide field of view, limited zoom.",
		{"scoped_fov": 30.0}
	))


func _add(mod: RifleMod) -> void:
	_mods[mod.id] = mod
