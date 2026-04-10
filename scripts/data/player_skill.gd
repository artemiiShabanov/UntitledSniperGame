class_name PlayerSkill
extends Resource
## A tiered passive skill purchased with XP.
## Each skill has 3-4 tiers with escalating cost and effect.

@export var id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
## Array of tier dictionaries: { "cost": int, "description": String, "stat_bonus": Dictionary }
## Tier 0 = not purchased. Tier indices are 1-based in this array (index 0 = tier 1).
@export var tiers: Array[Dictionary] = []


func get_max_tier() -> int:
	return tiers.size()


func get_tier_cost(tier: int) -> int:
	## tier is 1-based (1 = first purchase).
	if tier < 1 or tier > tiers.size():
		return -1
	return tiers[tier - 1].get("cost", 0)


func get_tier_description(tier: int) -> String:
	if tier < 1 or tier > tiers.size():
		return ""
	return tiers[tier - 1].get("description", "")


func get_tier_stat_bonus(tier: int) -> Dictionary:
	## Returns cumulative stat bonus up to and including the given tier.
	var result := {}
	for i in range(mini(tier, tiers.size())):
		var bonus: Dictionary = tiers[i].get("stat_bonus", {})
		for key: String in bonus:
			result[key] = result.get(key, 0.0) + bonus[key]
	return result
