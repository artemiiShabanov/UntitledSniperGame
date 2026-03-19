extends Node
## Manages game flow and per-run state.
## Autoloaded singleton. Handles state machine: HUB → DEPLOYING → IN_RUN → EXTRACTING → RESULT.

## ── Enums ────────────────────────────────────────────────────────────────────

enum GameState { HUB, DEPLOYING, IN_RUN, EXTRACTING, RESULT }

## ── Signals ──────────────────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal life_lost(lives_remaining: int)
signal run_failed
signal run_started
signal extraction_started
signal run_completed(success: bool)
signal run_timer_updated(time_left: float)
signal run_timer_expired

## ── Exports ──────────────────────────────────────────────────────────────────

@export var default_lives: int = 3
@export var default_run_time: float = 300.0  ## 5 minutes per run
@export var extraction_time: float = 3.0  ## Seconds to extract

## ── State ────────────────────────────────────────────────────────────────────

var game_state: GameState = GameState.HUB
var lives: int = 3
var max_lives: int = 3
var is_dead: bool = false

## Run timer
var run_timer: float = 0.0
var extraction_timer: float = 0.0

## Credits earned during this run (lost on death)
var run_credits: int = 0

## XP earned during this run (kept on death)
var run_xp: int = 0

## Ammo carried into the run
var carried_ammo: Dictionary = {}  ## { "standard": 20, "armor_piercing": 5 }

## Current level
var current_level_path: String = ""

## Run stats (for result screen)
var run_stats: Dictionary = {}

## Hit cooldown to prevent multiple hits in one frame
var hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 1.0

## Hub and level scene paths
const HUB_SCENE: String = "res://scenes/hub/hub.tscn"
const LOADING_SCENE: String = "res://scenes/ui/loading_screen.tscn"


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
	get_tree().change_scene_to_file.call_deferred(HUB_SCENE)


## ── Deploy ───────────────────────────────────────────────────────────────────

func deploy(level_path: String, ammo_loadout: Dictionary = {}) -> void:
	## Start a run: transition from hub to a level.
	current_level_path = level_path
	carried_ammo = ammo_loadout.duplicate()
	_set_game_state(GameState.DEPLOYING)

	# Reset run state
	max_lives = default_lives
	lives = max_lives
	is_dead = false
	run_credits = 0
	run_xp = 0
	hit_cooldown = 0.0
	run_timer = default_run_time
	run_stats = {
		"kills": 0,
		"headshots": 0,
		"shots_fired": 0,
		"shots_hit": 0,
		"credits_earned": 0,
		"xp_earned": 0,
		"time_survived": 0.0,
	}

	# Load the level
	get_tree().change_scene_to_file(level_path)

	# After scene loads, _on_level_ready() should be called by the level scene
	# or we transition to IN_RUN after a frame
	await get_tree().tree_changed
	begin_run()


func begin_run() -> void:
	## Called when the level is ready and player has spawned.
	_set_game_state(GameState.IN_RUN)
	run_started.emit()


## ── Run timer ────────────────────────────────────────────────────────────────

func _tick_run_timer(delta: float) -> void:
	run_timer -= delta
	run_stats.time_survived = default_run_time - run_timer
	run_timer_updated.emit(run_timer)

	if run_timer <= 0.0:
		run_timer = 0.0
		run_timer_expired.emit()
		_end_run_failure()


func get_run_time_remaining() -> float:
	return run_timer


func get_run_time_elapsed() -> float:
	return default_run_time - run_timer


## ── Extraction ───────────────────────────────────────────────────────────────

func begin_extraction() -> void:
	## Called when the player reaches the extraction point.
	if game_state != GameState.IN_RUN:
		return
	extraction_timer = extraction_time
	_set_game_state(GameState.EXTRACTING)
	extraction_started.emit()


func cancel_extraction() -> void:
	## Called if player leaves the extraction zone.
	if game_state != GameState.EXTRACTING:
		return
	_set_game_state(GameState.IN_RUN)


func _tick_extraction(delta: float) -> void:
	extraction_timer -= delta
	if extraction_timer <= 0.0:
		_end_run_success()


## ── Run end ──────────────────────────────────────────────────────────────────

func _end_run_success() -> void:
	_set_game_state(GameState.RESULT)

	# Commit earnings to save
	run_stats.credits_earned = run_credits
	run_stats.xp_earned = run_xp
	SaveManager.add_credits(run_credits)
	SaveManager.add_xp(run_xp)
	SaveManager.increment_stat("total_extractions")

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
	SaveManager.save()

	run_failed.emit()
	run_completed.emit(false)


## ── Hits ─────────────────────────────────────────────────────────────────────

func take_hit() -> void:
	if game_state != GameState.IN_RUN or is_dead:
		return
	if hit_cooldown > 0.0:
		return

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
	run_stats.shots_fired += 1


func record_shot_hit() -> void:
	run_stats.shots_hit += 1


func record_kill(headshot: bool = false) -> void:
	run_stats.kills += 1
	if headshot:
		run_stats.headshots += 1
