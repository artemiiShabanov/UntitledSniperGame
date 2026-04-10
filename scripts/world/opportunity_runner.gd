class_name OpportunityRunner
extends Node
## Manages in-run opportunities (dynamic events paired with army upgrades).
## Replaces LevelEventRunner. Added as a child of the level scene.
##
## Listens to threat_phase_changed. Each phase, checks if an opportunity should
## be offered. Tracks active opportunity timer and completion conditions.
## 1-2 opportunities per run, selected from eligible pool.

const MAX_OPPORTUNITIES_PER_RUN: int = 2
const OFFER_CHANCE: float = 0.5  ## 50% chance to offer on each eligible phase

var _offered_ids: Array[String] = []
var _active_opportunity: OpportunityData = null
var _active_timer: float = 0.0
var _active_kill_count: int = 0
var _active_kill_target: int = 1  ## How many kills/destroys needed to complete


func _ready() -> void:
	add_to_group("opportunity_runner")
	RunManager.threat_phase_changed.connect(_on_phase_changed)
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(func(_s: bool) -> void: _cancel_active())

	# Listen for kills and destructions to track completion.
	RunManager.enemy_killed_with_info.connect(_on_enemy_killed)
	RunManager.target_destroyed_with_info.connect(_on_target_destroyed)


func _on_run_started() -> void:
	_offered_ids.clear()
	_active_opportunity = null
	_active_timer = 0.0
	_active_kill_count = 0


func _process(delta: float) -> void:
	if _active_opportunity == null:
		return
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Instant opportunities (duration 0) don't tick down.
	if _active_opportunity.duration <= 0.0:
		return

	_active_timer -= delta
	if _active_timer <= 0.0:
		_fail_active()


func _on_phase_changed(phase: int) -> void:
	if _active_opportunity != null:
		return  # Already running one
	if _offered_ids.size() >= MAX_OPPORTUNITIES_PER_RUN:
		return  # Already offered enough this run

	var eligible := OpportunityRegistry.get_eligible(phase)
	# Remove already-offered ones.
	var pool: Array[OpportunityData] = []
	for opp in eligible:
		if opp.id not in _offered_ids:
			pool.append(opp)

	if pool.is_empty():
		return

	# Roll chance to offer.
	if randf() > OFFER_CHANCE:
		return

	_start_opportunity(pool.pick_random())


func _start_opportunity(opp: OpportunityData) -> void:
	_active_opportunity = opp
	_offered_ids.append(opp.id)
	_active_timer = opp.duration
	_active_kill_count = 0
	_active_kill_target = opp.kill_target

	if opp.duration > 0.0:
		RunManager.announce_event("%s — %.0fs" % [opp.name.to_upper(), opp.duration])
	else:
		RunManager.announce_event(opp.name.to_upper())


func _on_enemy_killed(_info: Dictionary) -> void:
	if _active_opportunity == null:
		return
	# For now, any hostile kill counts toward the active opportunity.
	# When specific opportunity targets are spawned (Section 6+), this will
	# check if the killed enemy is the opportunity target.
	_active_kill_count += 1
	if _active_kill_count >= _active_kill_target:
		_complete_active()


func _on_target_destroyed(_info: Dictionary) -> void:
	if _active_opportunity == null:
		return
	# Siege Assault: destroying siege equipment counts.
	if _active_opportunity.id in ["siege_assault", "siege_tower"]:
		_active_kill_count += 1
		if _active_kill_count >= _active_kill_target:
			_complete_active()


func _complete_active() -> void:
	var opp := _active_opportunity
	_active_opportunity = null

	RunManager.announce_event("%s COMPLETE" % opp.name.to_upper())
	RunManager.add_run_xp(opp.xp_reward)
	RunManager.run_stats.opportunities_completed += 1

	# Record in save data.
	var prior_completions := SaveManager.get_opportunity_completions(opp.id)
	SaveManager.record_opportunity_completion(opp.id)

	# First-ever completion unlocks the paired army upgrade.
	if prior_completions == 0 and opp.paired_army_upgrade_id != "":
		SaveManager.unlock_army_upgrade(opp.paired_army_upgrade_id)
		var upgrade := ArmyUpgradeRegistry.get_upgrade(opp.paired_army_upgrade_id)
		if upgrade:
			RunManager.announce_event("ARMY UPGRADE: %s" % upgrade.name.to_upper())

	AudioManager.play_sfx(&"opportunity_complete", Vector3.ZERO)


func _fail_active() -> void:
	var opp := _active_opportunity
	_active_opportunity = null
	RunManager.announce_event("%s FAILED" % opp.name.to_upper())


func _cancel_active() -> void:
	_active_opportunity = null
	_active_timer = 0.0
	_active_kill_count = 0


## ── Public API ──────────────────────────────────────────────────────────────

func get_active_opportunity() -> OpportunityData:
	return _active_opportunity


func get_active_time_remaining() -> float:
	return _active_timer if _active_opportunity else 0.0


func get_active_progress() -> String:
	## Returns "2/3" style progress string for HUD.
	if _active_opportunity == null:
		return ""
	return "%d/%d" % [_active_kill_count, _active_kill_target]
