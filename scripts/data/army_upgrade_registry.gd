extends Node
## Army Upgrade Registry — autoloaded singleton.
## 6 permanent upgrades, each unlocked by completing its paired opportunity.

var _upgrades: Dictionary = {}  ## { id: ArmyUpgrade }


func _ready() -> void:
	_register_all()


func get_upgrade(id: String) -> ArmyUpgrade:
	return _upgrades.get(id, null)


func get_all() -> Array[ArmyUpgrade]:
	var result: Array[ArmyUpgrade] = []
	for u: ArmyUpgrade in _upgrades.values():
		result.append(u)
	return result


func _register_all() -> void:
	_add(_create("champion_kill", "Hardened Warriors", "friendly_hp_mult", 0.3,
		"+30% friendly warrior HP.",
		"Your warriors wear reinforced armor forged in the castle smithy."))
	_add(_create("battle_training", "Battle Training", "friendly_damage_mult", 0.25,
		"+25% friendly warrior damage and hit chance.",
		"Veterans drill recruits in the courtyard before each battle."))
	_add(_create("reinforced_gates", "Reinforced Gates", "castle_hp_mult", 0.4,
		"+40% castle max HP.",
		"Iron-banded oak gates and thicker stone walls."))
	_add(_create("faster_muster", "Faster Muster", "friendly_spawn_rate_mult", 0.25,
		"+25% friendly warrior spawn rate.",
		"A horn rallies reinforcements from the surrounding villages."))
	_add(_create("archer_tower", "Archer Tower", "archer_tower", 1.0,
		"A friendly archer turret on the castle walls.",
		"Skilled bowmen man a tower overlooking the battlefield."))
	_add(_create("elite_guard", "Elite Guard", "elite_guard", 1.0,
		"Elite knights spawn every 5 phases.",
		"The king's personal guard joins the defense at critical moments."))


func _create(id: String, upgrade_name: String, effect_key: String, effect_value: float, desc: String, visual_desc: String) -> ArmyUpgrade:
	var u := ArmyUpgrade.new()
	u.id = id
	u.name = upgrade_name
	u.effect_key = effect_key
	u.effect_value = effect_value
	u.description = desc
	u.visual_description = visual_desc
	return u


func _add(upgrade: ArmyUpgrade) -> void:
	_upgrades[upgrade.id] = upgrade
