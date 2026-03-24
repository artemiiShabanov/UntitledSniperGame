class_name Contract
extends Resource
## A contract is a pre-run challenge with a bonus reward.
## Player picks one (or none) before deploying.

enum Type {
	KILL_COUNT,       ## Kill at least N enemies
	HEADSHOT_COUNT,   ## Get at least N headshots
	ACCURACY,         ## Finish with accuracy >= N%
	NO_HITS,          ## Extract without taking any damage
	SPEED_EXTRACT,    ## Extract within N seconds
	KILL_TARGET,      ## Kill a specific high-value target (future)
	DESTROY_TARGET,   ## Destroy a specific object (future)
}

@export var id: String = ""
@export var contract_name: String = ""
@export var description: String = ""
@export var type: Type = Type.KILL_COUNT
@export var target_value: float = 0.0  ## Meaning depends on type
@export var cost: int = 0  ## Credits to accept this contract
@export var bonus_credits: int = 0
@export var bonus_xp: int = 0
@export var level_restriction: String = ""  ## Level path; empty = any level
@export var target_id: String = ""  ## For KILL_TARGET/DESTROY_TARGET (future)


func is_available_for_level(level_path: String) -> bool:
	return level_restriction == "" or level_restriction == level_path


func check_completed(run_stats: Dictionary, lives: int, max_lives: int) -> bool:
	match type:
		Type.KILL_COUNT:
			return run_stats.get("kills", 0) >= int(target_value)
		Type.HEADSHOT_COUNT:
			return run_stats.get("headshots", 0) >= int(target_value)
		Type.ACCURACY:
			var fired: int = run_stats.get("shots_fired", 0)
			if fired == 0:
				return false
			var accuracy := float(run_stats.get("shots_hit", 0)) / float(fired) * 100.0
			return accuracy >= target_value
		Type.NO_HITS:
			return lives == max_lives
		Type.SPEED_EXTRACT:
			return run_stats.get("time_survived", 999.0) <= target_value
		Type.KILL_TARGET, Type.DESTROY_TARGET:
			# Future: check run_stats for target_id completion
			return false
	return false


static func create(p_id: String, p_name: String, p_desc: String, p_type: Type, p_target: float, p_cost: int, p_credits: int, p_xp: int, p_level: String = "", p_target_id: String = "") -> Contract:
	var c := Contract.new()
	c.id = p_id
	c.contract_name = p_name
	c.description = p_desc
	c.type = p_type
	c.target_value = p_target
	c.cost = p_cost
	c.bonus_credits = p_credits
	c.bonus_xp = p_xp
	c.level_restriction = p_level
	c.target_id = p_target_id
	return c
