class_name RunStats
extends RefCounted
## Typed container for per-run statistics. Owned by RunManager.
## Provides increment helpers and to_dict() for save/result-screen consumption.

var kills: int = 0
var headshots: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var credits_earned: int = 0
var xp_earned: int = 0
var time_survived: float = 0.0
var longest_kill_distance: float = 0.0
var contract_bonus_credits: int = 0
var contract_bonus_xp: int = 0
var npc_kills: int = 0
var targets_destroyed: int = 0


func reset() -> void:
	kills = 0
	headshots = 0
	shots_fired = 0
	shots_hit = 0
	credits_earned = 0
	xp_earned = 0
	time_survived = 0.0
	longest_kill_distance = 0.0
	contract_bonus_credits = 0
	contract_bonus_xp = 0
	npc_kills = 0
	targets_destroyed = 0


func record_shot_fired() -> void:
	shots_fired += 1


func record_shot_hit() -> void:
	shots_hit += 1


func record_kill(headshot: bool = false) -> void:
	kills += 1
	if headshot:
		headshots += 1


func record_distance(distance: float) -> void:
	if distance > longest_kill_distance:
		longest_kill_distance = distance


func to_dict() -> Dictionary:
	## Returns a plain Dictionary for save system and result screen compatibility.
	return {
		"kills": kills,
		"headshots": headshots,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"credits_earned": credits_earned,
		"xp_earned": xp_earned,
		"time_survived": time_survived,
		"longest_kill_distance": longest_kill_distance,
		"contract_bonus_credits": contract_bonus_credits,
		"contract_bonus_xp": contract_bonus_xp,
		"npc_kills": npc_kills,
		"targets_destroyed": targets_destroyed,
	}
