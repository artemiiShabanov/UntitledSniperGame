class_name PlayerSkill
extends Resource
## A permanent passive ability purchased with XP.

@export var id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var cost: int = 0  ## XP cost
@export var effect_key: String = ""  ## Used by systems to check if skill is active
@export var stat_bonus: Dictionary = {}  ## Optional stat modifiers (additive)
@export var icon: Texture2D  ## UI icon (assets/icons/skills/)


static func create(p_id: String, p_name: String, p_desc: String, p_cost: int, p_effect: String, p_stats: Dictionary = {}) -> PlayerSkill:
	var skill := PlayerSkill.new()
	skill.id = p_id
	skill.skill_name = p_name
	skill.description = p_desc
	skill.cost = p_cost
	skill.effect_key = p_effect
	skill.stat_bonus = p_stats
	return skill
