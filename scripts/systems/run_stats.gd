class_name RunStats
extends RefCounted
## Typed container for per-run statistics. Owned by RunManager.
## Provides increment helpers and to_dict() for save/result-screen consumption.

var kills: int = 0
var headshots: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var score_earned: int = 0
var xp_earned: int = 0
var time_survived: float = 0.0
var longest_kill_distance: float = 0.0
var targets_destroyed: int = 0
var opportunities_completed: int = 0
var friendly_kills: int = 0


func reset() -> void:
	kills = 0
	headshots = 0
	shots_fired = 0
	shots_hit = 0
	score_earned = 0
	xp_earned = 0
	time_survived = 0.0
	longest_kill_distance = 0.0
	targets_destroyed = 0
	opportunities_completed = 0
	friendly_kills = 0


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
	return {
		"kills": kills,
		"headshots": headshots,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"score_earned": score_earned,
		"xp_earned": xp_earned,
		"time_survived": time_survived,
		"longest_kill_distance": longest_kill_distance,
		"targets_destroyed": targets_destroyed,
		"opportunities_completed": opportunities_completed,
		"friendly_kills": friendly_kills,
	}
