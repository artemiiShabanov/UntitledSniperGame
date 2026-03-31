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
		"barrel_extended", "Extended Barrel", "barrel", 300,
		"Longer barrel for higher muzzle velocity. Less bullet drop at range.",
		{"muzzle_velocity": 420.0, "bullet_gravity": 9.8}
	))
	_add(RifleMod.create(
		"barrel_improvised_suppressor", "Improvised Suppressor", "barrel", 150,
		"A bottle jammed on the muzzle. Quieter shots, but velocity suffers.",
		{"muzzle_velocity": 240.0, "bullet_gravity": 9.8,
		 "gunshot_loudness": 15.0, "impact_loudness": 8.0},
		"suppressed"
	))
	_add(RifleMod.create(
		"barrel_tactical", "Tactical Barrel", "barrel", 500,
		"Integrated suppressor. Silent and precise — no velocity penalty.",
		{"muzzle_velocity": 300.0, "bullet_gravity": 9.8,
		 "gunshot_loudness": 20.0, "impact_loudness": 10.0},
		"suppressed"
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
	if not mod.icon:
		var icon_path := "res://assets/icons/mods/%s.png" % mod.id
		if ResourceLoader.exists(icon_path):
			mod.icon = load(icon_path)
	_mods[mod.id] = mod
