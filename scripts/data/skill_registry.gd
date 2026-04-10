extends Node
## Skill Registry — autoloaded singleton.
## Hardcoded 4 skills with tiered data per GDD §8.2.

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


func _register_all() -> void:
	_add(_create_skill("iron_lungs", "Iron Lungs",
		"Hold breath longer while scoped.", [
			{"cost": 100, "description": "+1s breath", "stat_bonus": {"breath_max": 1.0}},
			{"cost": 300, "description": "+3s breath", "stat_bonus": {"breath_max": 2.0}},
			{"cost": 600, "description": "+5s breath", "stat_bonus": {"breath_max": 2.0}},
		]))
	_add(_create_skill("quick_hands", "Quick Hands",
		"Faster bolt cycling.", [
			{"cost": 100, "description": "20% faster", "stat_bonus": {"bolt_cycle_mult": -0.2}},
			{"cost": 300, "description": "40% faster", "stat_bonus": {"bolt_cycle_mult": -0.2}},
			{"cost": 600, "description": "70% faster", "stat_bonus": {"bolt_cycle_mult": -0.3}},
		]))
	_add(_create_skill("last_stand", "Last Stand",
		"Start each run with extra lives.", [
			{"cost": 150, "description": "+1 life", "stat_bonus": {"bonus_lives": 1}},
			{"cost": 400, "description": "+2 lives", "stat_bonus": {"bonus_lives": 1}},
		]))
	_add(_create_skill("deep_pockets", "Deep Pockets",
		"Carry more bullets into each run.", [
			{"cost": 100, "description": "+10 bullets", "stat_bonus": {"bonus_bullets": 10}},
			{"cost": 250, "description": "+30 bullets", "stat_bonus": {"bonus_bullets": 20}},
			{"cost": 500, "description": "+50 bullets", "stat_bonus": {"bonus_bullets": 20}},
			{"cost": 800, "description": "+100 bullets", "stat_bonus": {"bonus_bullets": 50}},
		]))


func _create_skill(id: String, skill_name: String, desc: String, tiers: Array[Dictionary]) -> PlayerSkill:
	var skill := PlayerSkill.new()
	skill.id = id
	skill.skill_name = skill_name
	skill.description = desc
	skill.tiers = tiers
	var icon_path := "res://assets/icons/skills/%s.png" % id
	if ResourceLoader.exists(icon_path):
		skill.icon = load(icon_path)
	return skill


func _add(skill: PlayerSkill) -> void:
	_skills[skill.id] = skill
