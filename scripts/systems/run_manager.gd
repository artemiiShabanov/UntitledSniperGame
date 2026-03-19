extends Node
## Manages per-run state: lives, carried ammo, credits at risk.
## Autoloaded singleton. Reset at the start of each run.

## ── Signals ──────────────────────────────────────────────────────────────────

signal life_lost(lives_remaining: int)
signal run_failed
signal run_started

## ── Exports ──────────────────────────────────────────────────────────────────

@export var default_lives: int = 3

## ── State ────────────────────────────────────────────────────────────────────

var lives: int = 3
var max_lives: int = 3
var is_run_active: bool = false
var is_dead: bool = false

## Credits earned during this run (lost on death)
var run_credits: int = 0

## Hit cooldown to prevent multiple hits in one frame
var hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 1.0


func _process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta


## ── Run lifecycle ────────────────────────────────────────────────────────────

func start_run(starting_lives: int = -1) -> void:
	if starting_lives > 0:
		max_lives = starting_lives
	else:
		max_lives = default_lives
	lives = max_lives
	run_credits = 0
	is_run_active = true
	is_dead = false
	hit_cooldown = 0.0
	run_started.emit()


func end_run_success() -> void:
	## Called on successful extraction. Credits and ammo are kept.
	is_run_active = false


func end_run_failure() -> void:
	## Called when all lives are lost. Credits and ammo are lost.
	is_run_active = false
	is_dead = true
	run_credits = 0
	run_failed.emit()


## ── Hits ─────────────────────────────────────────────────────────────────────

func take_hit() -> void:
	if not is_run_active or is_dead:
		return
	if hit_cooldown > 0.0:
		return

	lives -= 1
	hit_cooldown = HIT_COOLDOWN_TIME
	life_lost.emit(lives)

	if lives <= 0:
		end_run_failure()


## ── Credits ──────────────────────────────────────────────────────────────────

func add_run_credits(amount: int) -> void:
	run_credits += amount


func get_run_credits() -> int:
	return run_credits
