extends Node
## Skill Registry — autoloaded singleton.
## Central catalog of all player skills.

var _skills: Dictionary = {}  ## { id: PlayerSkill }


func _ready() -> void:
	_register_all()


func get_skill(id: String) -> PlayerSkill:
	return _skills.get(id, null)


func get_all_skills() -> Array[PlayerSkill]:
	var result: Array[PlayerSkill] = []
	for skill: PlayerSkill in _skills.values():
		result.append(skill)
	return result


## ── Skill Definitions ───────────────────────────────────────────────────────

func _register_all() -> void:
	_add(PlayerSkill.create(
		"iron_lungs", "Iron Lungs",
		"Hold breath 2 seconds longer while scoped.",
		100, "longer_breath",
		{"breath_max": 2.0}
	))
	_add(PlayerSkill.create(
		"quick_hands", "Quick Hands",
		"Reload 20% faster. Stacks with bolt modifications.",
		150, "faster_reload",
		{"reload_time_mult": 0.8}
	))
	_add(PlayerSkill.create(
		"zipline_runner", "Zipline Runner",
		"Traverse ziplines 40% faster.",
		100, "faster_zipline",
		{"zipline_speed_mult": 1.4}
	))
	_add(PlayerSkill.create(
		"extra_life", "Last Stand",
		"Start each run with one extra life.",
		200, "extra_life",
		{"bonus_lives": 1}
	))


func _add(skill: PlayerSkill) -> void:
	_skills[skill.id] = skill
