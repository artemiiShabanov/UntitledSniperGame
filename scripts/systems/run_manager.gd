extends Node
## Manages game flow and per-run state.
## Autoloaded singleton. Handles state machine: HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT.

## ── Enums ────────────────────────────────────────────────────────────────────

enum GameState { HUB, DEPLOYING, IN_RUN, EXTRACTING, RESULT }
const THREAT_PHASE_MIN: int = 1
const THREAT_PHASE_MAX: int = 20
const PHASE_DURATION: float = 60.0  ## Seconds per phase

## ── Signals ──────────────────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal life_lost(lives_remaining: int)
signal run_failed
signal run_started
signal extraction_started
signal extraction_cancelled
signal extraction_progress_updated(progress: float)  ## 0.0 to 1.0
signal run_completed(success: bool)
signal threat_phase_changed(phase: int)
signal enemy_killed_with_info(info: Dictionary)  ## {enemy, headshot, distance, score}
signal friendly_killed_with_info(info: Dictionary)  ## {penalty}
signal target_destroyed_with_info(info: Dictionary)  ## {score}
signal event_announced(text: String)
signal castle_hp_changed(hp: int, max_hp: int)
signal castle_destroyed
signal extraction_window_opened(duration: float)
signal extraction_window_closed
signal score_changed(score: int)

## ── Exports ──────────────────────────────────────────────────────────────────

@export var default_lives: int = 3
@export var extraction_time: float = 3.0  ## Seconds to hold E for extraction
@export var default_castle_hp: int = 100

## ── Extraction Window Schedule ──────────────────────────────────────────────
## { phase_after: duration } — window opens after the given phase ends.

const EXTRACTION_SCHEDULE := {
	2: 15.0, 4: 15.0, 6: 15.0,     # Early
	7: 10.0, 10: 10.0, 13: 10.0,   # Mid
	15: 8.0, 19: 8.0,               # Late
}

## ── State ────────────────────────────────────────────────────────────────────

var game_state: GameState = GameState.HUB
var lives: int = 3
var max_lives: int = 3
var is_dead: bool = false

## Run timer (count-up — no expiry)
var run_elapsed: float = 0.0
var extraction_timer: float = 0.0

## Threat phase (1-20)
var threat_phase: int = 1

## Score earned during this run
var run_score: int = 0

## XP earned during this run (kept on death)
var run_xp: int = 0

## Castle HP
var castle_hp: int = 100
var castle_max_hp: int = 100

## Extraction window
var extraction_window_open: bool = false
var extraction_window_timer: float = 0.0

## Current level
var current_level_path: String = ""

## Run stats
var run_stats: RunStats = RunStats.new()

## Hit cooldown
var hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 1.0

## Hub scene path
const HUB_SCENE: String = "res://scenes/hub/hub.tscn"


func _process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

	match game_state:
		GameState.IN_RUN:
			_tick_run_timer(delta)
			_tick_extraction_window(delta)
		GameState.EXTRACTING:
			_tick_extraction(delta)
			_tick_extraction_window(delta)


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

func deploy(level_path: String) -> void:
	current_level_path = level_path
	_set_game_state(GameState.DEPLOYING)

	# Reset run state
	max_lives = default_lives
	var bonus_lives: int = int(SaveManager.get_skill_stat_bonus("bonus_lives"))
	max_lives += bonus_lives
	lives = max_lives
	is_dead = false
	run_score = 0
	run_xp = 0
	hit_cooldown = 0.0
	run_elapsed = 0.0
	threat_phase = THREAT_PHASE_MIN
	run_stats.reset()

	# Castle HP (with army upgrade bonus)
	castle_max_hp = default_castle_hp
	if SaveManager.is_army_upgrade_unlocked("reinforced_gates"):
		var upgrade := ArmyUpgradeRegistry.get_upgrade("reinforced_gates")
		if upgrade:
			castle_max_hp = int(castle_max_hp * (1.0 + upgrade.effect_value))
	castle_hp = castle_max_hp

	# Extraction window
	extraction_window_open = false
	extraction_window_timer = 0.0

	await LoadingScreen.transition(func() -> void:
		get_tree().change_scene_to_file(level_path)
	)
	begin_run()


func begin_run() -> void:
	_set_game_state(GameState.IN_RUN)
	run_started.emit()


## ── Run timer (count-up) ────────────────────────────────────────────────────

func _tick_run_timer(delta: float) -> void:
	run_elapsed += delta
	run_stats.time_survived = run_elapsed
	_update_threat_phase()


func get_run_time_elapsed() -> float:
	return run_elapsed


## ── Extraction ───────────────────────────────────────────────────────────────

func begin_extraction() -> void:
	if game_state != GameState.IN_RUN:
		return
	if not extraction_window_open:
		return
	extraction_timer = extraction_time
	_set_game_state(GameState.EXTRACTING)
	extraction_started.emit()


func cancel_extraction() -> void:
	if game_state != GameState.EXTRACTING:
		return
	extraction_timer = 0.0
	extraction_progress_updated.emit(0.0)
	extraction_cancelled.emit()
	_set_game_state(GameState.IN_RUN)


func get_extraction_progress() -> float:
	if extraction_time <= 0.0:
		return 1.0
	return 1.0 - (extraction_timer / extraction_time)


func _tick_extraction(delta: float) -> void:
	extraction_timer -= delta
	extraction_progress_updated.emit(get_extraction_progress())
	if extraction_timer <= 0.0:
		_end_run_success()


## ── Extraction Window ───────────────────────────────────────────────────────

func _tick_extraction_window(delta: float) -> void:
	if not extraction_window_open:
		return
	extraction_window_timer -= delta
	if extraction_window_timer <= 0.0:
		_close_extraction_window()


func _open_extraction_window(duration: float) -> void:
	extraction_window_open = true
	extraction_window_timer = duration
	extraction_window_opened.emit(duration)


func _close_extraction_window() -> void:
	extraction_window_open = false
	extraction_window_timer = 0.0
	# Cancel in-progress extraction if window closes
	if game_state == GameState.EXTRACTING:
		cancel_extraction()
	extraction_window_closed.emit()


## ── Run end ──────────────────────────────────────────────────────────────────

func _end_run_success() -> void:
	AudioManager.play_sfx_2d(&"extraction_complete")
	_set_game_state(GameState.RESULT)

	run_stats.score_earned = run_score
	run_stats.xp_earned = run_xp
	SaveManager.add_xp(run_xp)
	SaveManager.increment_stat("total_extractions")

	# Tick durability on equipped mods
	SaveManager.tick_mod_durability()

	SaveManager.commit_run_stats(run_stats.to_dict(), current_level_path, true)
	SaveManager.save()
	run_completed.emit(true)


func _end_run_failure() -> void:
	is_dead = true
	_set_game_state(GameState.RESULT)

	run_stats.score_earned = 0
	run_stats.xp_earned = run_xp
	run_score = 0

	# XP is kept, but all equipped mods are lost
	SaveManager.add_xp(run_xp)
	SaveManager.strip_equipped_mods()
	SaveManager.increment_stat("total_deaths")

	SaveManager.commit_run_stats(run_stats.to_dict(), current_level_path, false)
	SaveManager.save()

	run_failed.emit()
	run_completed.emit(false)


## ── Castle HP ───────────────────────────────────────────────────────────────

func castle_take_damage(amount: int) -> void:
	if castle_hp <= 0:
		return
	castle_hp = maxi(castle_hp - amount, 0)
	castle_hp_changed.emit(castle_hp, castle_max_hp)
	if castle_hp <= 0:
		castle_destroyed.emit()
		_end_run_failure()


## ── Hits ─────────────────────────────────────────────────────────────────────

func take_hit() -> void:
	if is_dead:
		return
	if game_state != GameState.IN_RUN and game_state != GameState.EXTRACTING:
		return
	if hit_cooldown > 0.0:
		return

	if game_state == GameState.EXTRACTING:
		cancel_extraction()

	lives -= 1
	hit_cooldown = HIT_COOLDOWN_TIME
	life_lost.emit(lives)

	if lives <= 0:
		_end_run_failure()


## ── Score ───────────────────────────────────────────────────────────────────

func add_run_score(amount: int) -> void:
	run_score += amount
	run_stats.score_earned = run_score
	score_changed.emit(run_score)


func add_run_xp(amount: int) -> void:
	run_xp += amount
	run_stats.xp_earned = run_xp


func get_run_score() -> int:
	return run_score


## ── Stats ────────────────────────────────────────────────────────────────────

func record_shot_fired() -> void:
	run_stats.record_shot_fired()


func record_shot_hit() -> void:
	run_stats.record_shot_hit()


func record_kill(headshot: bool = false) -> void:
	run_stats.record_kill(headshot)


## ── Kill scoring ────────────────────────────────────────────────────────────

func record_kill_with_score(enemy: Node3D, headshot: bool, base_score: int) -> Dictionary:
	## Records a kill with headshot bonus. No distance multiplier.
	record_kill(headshot)

	var distance := 0.0
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		distance = players[0].global_position.distance_to(enemy.global_position)
	run_stats.record_distance(distance)

	var head_mult := 2.0 if headshot else 1.0
	var final_score := int(base_score * head_mult)

	add_run_score(final_score)
	add_run_xp(final_score)

	var info := {
		"enemy": enemy,
		"headshot": headshot,
		"distance": distance,
		"base_score": base_score,
		"final_score": final_score,
		"headshot_multiplier": head_mult,
	}

	enemy_killed_with_info.emit(info)
	return info


func record_friendly_kill(penalty_score: int) -> void:
	## Deducts score for killing a friendly warrior.
	run_score = maxi(run_score - penalty_score, 0)
	run_stats.score_earned = run_score
	run_stats.friendly_kills += 1
	score_changed.emit(run_score)

	friendly_killed_with_info.emit({"penalty": penalty_score})


## ── Target Destruction ──────────────────────────────────────────────────────

func record_target_destroyed(score: int) -> void:
	run_stats.targets_destroyed += 1
	add_run_score(score)
	add_run_xp(score)

	target_destroyed_with_info.emit({"score": score})


## ── Event Announcements ─────────────────────────────────────────────────────

func announce_event(text: String) -> void:
	event_announced.emit(text)


## ── Threat Phase ────────────────────────────────────────────────────────────

func _update_threat_phase() -> void:
	## Phase = floor(elapsed / 60) + 1, capped at 20.
	var new_phase := clampi(int(run_elapsed / PHASE_DURATION) + 1, THREAT_PHASE_MIN, THREAT_PHASE_MAX)

	if new_phase != threat_phase:
		var old_phase := threat_phase
		threat_phase = new_phase
		threat_phase_changed.emit(threat_phase)

		# Check if an extraction window should open after the old phase.
		if EXTRACTION_SCHEDULE.has(old_phase):
			_open_extraction_window(EXTRACTION_SCHEDULE[old_phase])


func get_threat_phase_name() -> String:
	return "PHASE %d" % threat_phase
