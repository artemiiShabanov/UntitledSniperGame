class_name Weapon
extends Node3D
## Sniper rifle weapon controller.
## Manages scope zoom, bolt-action cycling, reload, and inspect states.
## Attach to a Weapon node under Head.

## ── Enums ────────────────────────────────────────────────────────────────────

enum State { IDLE, AIMING, BOLT_CYCLING, RELOADING, INSPECTING }

## ── Exports ──────────────────────────────────────────────────────────────────

## Scope
@export var default_fov: float = 70.0
@export var scoped_fov: float = 15.0
@export var scope_lerp_speed: float = 12.0
@export var scoped_sensitivity_mult: float = 0.3

## Bolt action
@export var bolt_cycle_time: float = 1.2  ## Seconds to cycle bolt after a shot

## Reload
@export var reload_time: float = 2.5
@export var magazine_size: int = 5

## Inspect
@export var inspect_duration: float = 2.0

## ── State ────────────────────────────────────────────────────────────────────

var state: State = State.IDLE
var is_scoped: bool = false
var state_timer: float = 0.0

## Ammo (managed here for now, will integrate with SaveManager in Layer 3)
var ammo_in_magazine: int = 5
var ammo_reserve: int = 20

## ── Signals ──────────────────────────────────────────────────────────────────

signal shot_fired
signal reload_complete
signal bolt_cycled
signal state_changed(new_state: State)

## ── Node references ──────────────────────────────────────────────────────────

@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CharacterBody3D = owner


func _ready() -> void:
	assert(camera != null, "Weapon must be a child of Camera3D")


func _process(delta: float) -> void:
	_process_state_timer(delta)
	_process_scope(delta)
	_process_input()


## ── State machine ────────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)


func _process_state_timer(delta: float) -> void:
	if state_timer <= 0.0:
		return

	state_timer -= delta
	if state_timer <= 0.0:
		match state:
			State.BOLT_CYCLING:
				bolt_cycled.emit()
				_set_state(State.AIMING if is_scoped else State.IDLE)
			State.RELOADING:
				_finish_reload()
			State.INSPECTING:
				_set_state(State.IDLE)


func can_shoot() -> bool:
	return state in [State.IDLE, State.AIMING] and ammo_in_magazine > 0


func can_reload() -> bool:
	return state in [State.IDLE, State.AIMING] and ammo_in_magazine < magazine_size and ammo_reserve > 0


func is_busy() -> bool:
	return state in [State.BOLT_CYCLING, State.RELOADING, State.INSPECTING]


func _cancel_inspect() -> void:
	if state == State.INSPECTING:
		state_timer = 0.0
		_set_state(State.IDLE)


## ── Scope ────────────────────────────────────────────────────────────────────

func _process_scope(delta: float) -> void:
	var wants_scope := Input.is_action_pressed("zoom") and not is_busy()

	if wants_scope and not is_scoped:
		is_scoped = true
		if state == State.IDLE:
			_set_state(State.AIMING)
	elif not wants_scope and is_scoped:
		is_scoped = false
		if state == State.AIMING:
			_set_state(State.IDLE)

	# Lerp FOV
	var target_fov := scoped_fov if is_scoped else default_fov
	camera.fov = lerp(camera.fov, target_fov, scope_lerp_speed * delta)


func get_sensitivity_multiplier() -> float:
	## Player.gd multiplies mouse sensitivity by this value.
	if is_scoped:
		return scoped_sensitivity_mult
	return 1.0


## ── Input ────────────────────────────────────────────────────────────────────

func _process_input() -> void:
	# Cancel inspect on combat input
	if state == State.INSPECTING:
		if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("zoom") \
				or Input.is_action_just_pressed("reload"):
			_cancel_inspect()

	# Shoot
	if Input.is_action_just_pressed("shoot"):
		try_shoot()

	# Reload
	if Input.is_action_just_pressed("reload"):
		try_reload()

	# Inspect
	if Input.is_action_just_pressed("inspect") and state == State.IDLE:
		_start_inspect()


## ── Actions ──────────────────────────────────────────────────────────────────

func try_shoot() -> void:
	if not can_shoot():
		return

	ammo_in_magazine -= 1
	shot_fired.emit()

	# Enter bolt cycling
	state_timer = bolt_cycle_time
	_set_state(State.BOLT_CYCLING)


func try_reload() -> void:
	if not can_reload():
		return

	is_scoped = false
	state_timer = reload_time
	_set_state(State.RELOADING)


func _finish_reload() -> void:
	var needed := magazine_size - ammo_in_magazine
	var available := mini(needed, ammo_reserve)
	ammo_in_magazine += available
	ammo_reserve -= available
	reload_complete.emit()
	_set_state(State.IDLE)


func _start_inspect() -> void:
	is_scoped = false
	state_timer = inspect_duration
	_set_state(State.INSPECTING)
