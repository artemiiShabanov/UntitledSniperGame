extends Node
## Manages game flow and per-run state.
## Autoloaded singleton. Handles state machine: HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT.

## ── Enums ────────────────────────────────────────────────────────────────────

enum GameState { HUB, DEPLOYING, IN_RUN, EXTRACTING, RESULT }
enum ThreatPhase { EARLY, MID, LATE }

## ── Signals ──────────────────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal life_lost(lives_remaining: int)
signal run_failed
signal run_started
signal extraction_started
signal extraction_cancelled
signal extraction_progress_updated(progress: float)  ## 0.0 to 1.0
signal run_completed(success: bool)
signal run_timer_updated(time_left: float)
signal run_timer_expired
signal threat_phase_changed(phase: ThreatPhase)
signal enemy_killed_with_info(info: Dictionary)  ## {enemy, headshot, distance, credits, xp}
signal npc_killed_with_info(info: Dictionary)  ## {penalty, npc_kills}
signal target_destroyed_with_info(info: Dictionary)  ## {credits, xp}

## ── Exports ──────────────────────────────────────────────────────────────────

@export var default_lives: int = 3
@export var default_run_time: float = 300.0  ## 5 minutes per run
@export var extraction_time: float = 3.0  ## Seconds to extract

## Threat phase timing (seconds of elapsed time)
@export var early_phase_duration: float = 60.0   ## Seconds in EARLY phase before MID
@export var mid_phase_duration: float = 120.0    ## Seconds in MID phase before LATE

## ── State ────────────────────────────────────────────────────────────────────

var game_state: GameState = GameState.HUB
var lives: int = 3
var max_lives: int = 3
var is_dead: bool = false

## Run timer
var run_timer: float = 0.0
var run_start_time: float = 0.0  ## Actual starting value of run_timer (may differ from default)
var extraction_timer: float = 0.0

## Threat phase
var threat_phase: ThreatPhase = ThreatPhase.EARLY

## Credits earned during this run (lost on death)
var run_credits: int = 0

## XP earned during this run (kept on death)
var run_xp: int = 0

## Ammo carried into the run
var carried_ammo: Dictionary = {}  ## { "standard": 20, "armor_piercing": 5 }

## Current level
var current_level_path: String = ""

## Active contract (null if none selected)
var active_contract: Contract = null
var contract_completed: bool = false

## Run stats (typed container — use .to_dict() for save/result screen)
var run_stats: RunStats = RunStats.new()

## Hit cooldown to prevent multiple hits in one frame
var hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 1.0

## Hub and level scene paths
const HUB_SCENE: String = "res://scenes/hub/hub.tscn"


func _process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

	match game_state:
		GameState.IN_RUN:
			_tick_run_timer(delta)
		GameState.EXTRACTING:
			_tick_extraction(delta)


## ── State machine ────────────────────────────────────────────────────────────

func _set_game_state(new_state: GameState) -> void:
	game_state = new_state
	state_changed.emit(new_state)


## ── Hub ──────────────────────────────────────────────────────────────────────

func go_to_hub() -> void:
	_set_game_state(GameState.HUB)
	is_dead = false
	LoadingScreen.transition(func() -> void:
		get_tree().change_scene_to_file(HUB_SCENE)
	)


## ── Deploy ───────────────────────────────────────────────────────────────────

func deploy(level_path: String, ammo_loadout: Dictionary = {}) -> void:
	## Start a run: transition from hub to a level.
	current_level_path = level_path
	carried_ammo = ammo_loadout.duplicate()
	_set_game_state(GameState.DEPLOYING)

	# Reset run state
	max_lives = default_lives
	var bonus_lives: int = int(SaveManager.get_skill_stat_bonus("bonus_lives"))
	max_lives += bonus_lives
	lives = max_lives
	is_dead = false
	run_credits = 0
	run_xp = 0
	hit_cooldown = 0.0
	run_timer = default_run_time
	run_start_time = default_run_time
	threat_phase = ThreatPhase.EARLY
	contract_completed = false
	run_stats.reset()

	# Load the level behind a loading screen
	await LoadingScreen.transition(func() -> void:
		get_tree().change_scene_to_file(level_path)
	)
	begin_run()


func begin_run() -> void:
	## Called when the level is ready and player has spawned.
	_set_game_state(GameState.IN_RUN)
	run_started.emit()


## ── Run timer ────────────────────────────────────────────────────────────────

func _tick_run_timer(delta: float) -> void:
	run_timer -= delta
	run_stats.time_survived = run_start_time - run_timer

	run_timer_updated.emit(run_timer)
	_update_threat_phase()

	if run_timer <= 0.0:
		run_timer = 0.0
		run_timer_expired.emit()
		_end_run_failure()


func get_run_time_remaining() -> float:
	return run_timer


func get_run_time_elapsed() -> float:
	return run_start_time - run_timer


## ── Extraction ───────────────────────────────────────────────────────────────

func begin_extraction() -> void:
	## Called when the player reaches the extraction point.
	if game_state != GameState.IN_RUN:
		return
	extraction_timer = extraction_time
	_set_game_state(GameState.EXTRACTING)
	extraction_started.emit()


func cancel_extraction() -> void:
	## Called if player leaves the extraction zone or releases E.
	if game_state != GameState.EXTRACTING:
		return
	extraction_timer = 0.0
	extraction_progress_updated.emit(0.0)
	extraction_cancelled.emit()
	_set_game_state(GameState.IN_RUN)


func get_extraction_progress() -> float:
	## Returns 0.0 to 1.0 extraction completion.
	if extraction_time <= 0.0:
		return 1.0
	return 1.0 - (extraction_timer / extraction_time)


func _tick_extraction(delta: float) -> void:
	extraction_timer -= delta
	extraction_progress_updated.emit(get_extraction_progress())
	if extraction_timer <= 0.0:
		_end_run_success()


## ── Run end ──────────────────────────────────────────────────────────────────

func _end_run_success() -> void:
	AudioManager.play_sfx_2d(&"extraction_complete")
	_set_game_state(GameState.RESULT)

	# Check contract completion
	if active_contract:
		contract_completed = active_contract.check_completed(run_stats.to_dict(), lives, max_lives)
		if contract_completed:
			run_credits += active_contract.bonus_credits
			run_xp += active_contract.bonus_xp
			run_stats.contract_bonus_credits = active_contract.bonus_credits
			run_stats.contract_bonus_xp = active_contract.bonus_xp

	# Commit earnings to save
	run_stats.credits_earned = run_credits
	run_stats.xp_earned = run_xp
	SaveManager.add_credits(run_credits)
	SaveManager.add_xp(run_xp)
	SaveManager.increment_stat("total_extractions")

	# Aggregate run stats into lifetime totals, records, and per-level stats
	SaveManager.commit_run_stats(run_stats.to_dict(), current_level_path, true)

	# Return unused ammo to inventory
	if not SaveManager.data.has("ammo_inventory"):
		SaveManager.data["ammo_inventory"] = {}
	var inv: Dictionary = SaveManager.data["ammo_inventory"]
	for ammo_type in carried_ammo:
		inv[ammo_type] = inv.get(ammo_type, 0) + carried_ammo[ammo_type]

	SaveManager.save()
	run_completed.emit(true)


func _end_run_failure() -> void:
	is_dead = true
	_set_game_state(GameState.RESULT)

	# Lose all credits + carried ammo
	run_stats.credits_earned = 0
	run_stats.xp_earned = run_xp
	run_credits = 0
	carried_ammo = {}

	# XP is still kept
	SaveManager.add_xp(run_xp)
	SaveManager.increment_stat("total_deaths")

	# Aggregate run stats into lifetime totals, records, and per-level stats
	SaveManager.commit_run_stats(run_stats.to_dict(), current_level_path, false)

	SaveManager.save()

	run_failed.emit()
	run_completed.emit(false)


## ── Hits ─────────────────────────────────────────────────────────────────────

func take_hit() -> void:
	if is_dead:
		return
	# Allow hits during extraction too (cancels it)
	if game_state != GameState.IN_RUN and game_state != GameState.EXTRACTING:
		return
	if hit_cooldown > 0.0:
		return

	# Damage cancels extraction
	if game_state == GameState.EXTRACTING:
		cancel_extraction()

	lives -= 1
	hit_cooldown = HIT_COOLDOWN_TIME
	life_lost.emit(lives)

	if lives <= 0:
		_end_run_failure()


## ── Credits & XP ─────────────────────────────────────────────────────────────

func add_run_credits(amount: int) -> void:
	run_credits += amount
	run_stats.credits_earned = run_credits


func add_run_xp(amount: int) -> void:
	run_xp += amount
	run_stats.xp_earned = run_xp


func get_run_credits() -> int:
	return run_credits


## ── Ammo ─────────────────────────────────────────────────────────────────────

func get_carried_ammo(ammo_type: String) -> int:
	return carried_ammo.get(ammo_type, 0)


func consume_ammo(ammo_type: String, amount: int = 1) -> bool:
	## Returns true if ammo was available and consumed.
	var current: int = carried_ammo.get(ammo_type, 0)
	if current < amount:
		return false
	carried_ammo[ammo_type] = current - amount
	return true


## ── Stats ────────────────────────────────────────────────────────────────────

func record_shot_fired() -> void:
	run_stats.record_shot_fired()


func record_shot_hit() -> void:
	run_stats.record_shot_hit()


func record_kill(headshot: bool = false) -> void:
	run_stats.record_kill(headshot)


## ── NPC Kill Penalty ────────────────────────────────────────────────────────

func record_npc_kill(penalty: int) -> void:
	## Deducts credits for killing a neutral NPC.
	run_credits = maxi(run_credits - penalty, 0)
	run_stats.credits_earned = run_credits
	run_stats.npc_kills += 1

	var info := {
		"penalty": penalty,
		"npc_kills": run_stats.npc_kills,
	}
	npc_killed_with_info.emit(info)


## ── Target Destruction ──────────────────────────────────────────────────────

func record_target_destroyed(credits: int, xp: int) -> void:
	## Records a destructible target being destroyed. Awards credits and XP.
	run_stats.targets_destroyed += 1
	add_run_credits(credits)
	add_run_xp(xp)

	var info := {
		"credits": credits,
		"xp": xp,
		"targets_destroyed": run_stats.targets_destroyed,
	}
	target_destroyed_with_info.emit(info)


## ── Threat Phase ────────────────────────────────────────────────────────────

func _update_threat_phase() -> void:
	var elapsed := get_run_time_elapsed()
	var new_phase: ThreatPhase

	if elapsed < early_phase_duration:
		new_phase = ThreatPhase.EARLY
	elif elapsed < early_phase_duration + mid_phase_duration:
		new_phase = ThreatPhase.MID
	else:
		new_phase = ThreatPhase.LATE

	if new_phase != threat_phase:
		threat_phase = new_phase
		threat_phase_changed.emit(threat_phase)


func get_threat_phase_name() -> String:
	match threat_phase:
		ThreatPhase.EARLY:
			return "EARLY"
		ThreatPhase.MID:
			return "MID"
		ThreatPhase.LATE:
			return "LATE"
	return "UNKNOWN"


## ── Distance Bonus ──────────────────────────────────────────────────────────

func calc_distance_multiplier(distance: float) -> float:
	## Returns credit multiplier based on kill distance.
	## 1.0x at <100m, 1.5x at 100m, 2.0x at 150m, 3.0x at 200m+
	if distance < 100.0:
		return 1.0
	elif distance < 150.0:
		return lerpf(1.5, 2.0, (distance - 100.0) / 50.0)
	elif distance < 200.0:
		return lerpf(2.0, 3.0, (distance - 150.0) / 50.0)
	else:
		return 3.0


func record_kill_with_bonus(enemy: Node3D, headshot: bool, base_credits: int, base_xp: int) -> Dictionary:
	## Records a kill with distance and headshot bonuses applied.
	## Returns info dict for the kill feed.
	record_kill(headshot)

	var distance := 0.0
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		distance = players[0].global_position.distance_to(enemy.global_position)

	if distance > run_stats.longest_kill_distance:
		run_stats.longest_kill_distance = distance

	var dist_mult := calc_distance_multiplier(distance)
	var head_mult := 2.0 if headshot else 1.0
	var total_mult := dist_mult * head_mult

	var final_credits := int(base_credits * total_mult)
	var final_xp := int(base_xp * total_mult)

	add_run_credits(final_credits)
	add_run_xp(final_xp)

	var info := {
		"enemy": enemy,
		"headshot": headshot,
		"distance": distance,
		"base_credits": base_credits,
		"final_credits": final_credits,
		"final_xp": final_xp,
		"distance_multiplier": dist_mult,
		"headshot_multiplier": head_mult,
		"total_multiplier": total_mult,
	}

	AudioManager.play_sfx_2d(&"credits_gain")
	enemy_killed_with_info.emit(info)
	return info
