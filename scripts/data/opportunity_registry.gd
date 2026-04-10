extends Node
## Opportunity Registry — autoloaded singleton.
## 6 opportunities loaded from hardcoded data. Each paired 1:1 with an army upgrade.

var _opportunities: Dictionary = {}  ## { id: OpportunityData }


func _ready() -> void:
	_register_all()


func get_opportunity(id: String) -> OpportunityData:
	return _opportunities.get(id, null)


func get_all() -> Array[OpportunityData]:
	var result: Array[OpportunityData] = []
	for opp: OpportunityData in _opportunities.values():
		result.append(opp)
	return result


func get_eligible(phase: int) -> Array[OpportunityData]:
	## Returns opportunities whose phase_range includes the given phase.
	var result: Array[OpportunityData] = []
	for opp: OpportunityData in _opportunities.values():
		if phase >= opp.phase_range.x and phase <= opp.phase_range.y:
			result.append(opp)
	return result


func _register_all() -> void:
	_add(_create("enemy_champion", "Enemy Champion", "champion_kill",
		Vector2i(4, 15), 60.0, "A tougher warrior approaches. Kill before it reaches the castle.", 150, 1))
	_add(_create("archer_ambush", "Archer Ambush", "battle_training",
		Vector2i(6, 16), 45.0, "Archers appear at unexpected positions. Eliminate them all.", 120, 3))
	_add(_create("siege_assault", "Siege Assault", "reinforced_gates",
		Vector2i(8, 18), 90.0, "Multiple siege weapons activate. Destroy them all.", 200, 3))
	_add(_create("war_horn", "War Horn", "faster_muster",
		Vector2i(5, 15), 0.0, "A horn carrier appears briefly. One shot opportunity.", 100, 1))
	_add(_create("siege_tower", "Siege Tower", "archer_tower",
		Vector2i(10, 20), 60.0, "A siege tower approaches. Destroy it before arrival.", 180, 1))
	_add(_create("war_chief", "War Chief", "elite_guard",
		Vector2i(12, 20), 45.0, "An enemy commander buffs nearby warriors. Kill to break the buff.", 200, 1))


func _create(id: String, opp_name: String, upgrade_id: String, phase_range: Vector2i, duration: float, desc: String, xp: int, kills: int = 1) -> OpportunityData:
	var opp := OpportunityData.new()
	opp.id = id
	opp.name = opp_name
	opp.paired_army_upgrade_id = upgrade_id
	opp.phase_range = phase_range
	opp.duration = duration
	opp.description = desc
	opp.xp_reward = xp
	opp.kill_target = kills
	return opp


func _add(opp: OpportunityData) -> void:
	_opportunities[opp.id] = opp
