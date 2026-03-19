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

## Sway
@export var sway_amplitude: float = 0.003  ## Base sway strength (radians)
@export var sway_speed: float = 1.5  ## Sway oscillation speed
@export var sway_penalty_mult: float = 2.5  ## Sway multiplier after breath exhaustion

## Hold breath
@export var breath_max: float = 3.0  ## Seconds of hold breath
@export var breath_recharge_rate: float = 0.75  ## Seconds of breath regained per second
@export var breath_penalty_duration: float = 1.5  ## Extra-sway penalty time after exhaustion
@export var breath_sway_mult: float = 0.1  ## Sway multiplier while holding breath

## Hipfire
@export var hipfire_spread_deg: float = 2.0  ## Spread angle in degrees when unscoped

## Bullet
@export var bullet_scene: PackedScene = preload("res://scenes/projectile/bullet.tscn")
@export var muzzle_velocity: float = 300.0
@export var bullet_gravity: float = 9.8

## ── State ────────────────────────────────────────────────────────────────────

var state: State = State.IDLE
var is_scoped: bool = false
var state_timer: float = 0.0

## Ammo
var ammo_in_magazine: int = 5
var ammo_reserve: int = 20

## Sway & breath
var sway_time: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO  ## Current applied sway (to undo next frame)
var breath_remaining: float = 3.0
var is_holding_breath: bool = false
var breath_exhausted_timer: float = 0.0  ## > 0 means penalty sway active

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
	breath_remaining = breath_max


func _process(delta: float) -> void:
	_process_state_timer(delta)
	_process_scope(delta)
	_process_sway(delta)
	_process_breath(delta)
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


## ── Sway ─────────────────────────────────────────────────────────────────────

func _process_sway(delta: float) -> void:
	# Remove previous frame's sway offset
	camera.rotation.x -= sway_offset.x
	camera.rotation.y -= sway_offset.y

	if not is_scoped:
		sway_time = 0.0
		sway_offset = Vector2.ZERO
		return

	sway_time += delta * sway_speed

	var sway_mult := 1.0
	if is_holding_breath:
		sway_mult = breath_sway_mult
	elif breath_exhausted_timer > 0.0:
		sway_mult = sway_penalty_mult

	sway_offset.x = sin(sway_time * 1.1) * sway_amplitude * sway_mult
	sway_offset.y = sin(sway_time * 0.7) * sway_amplitude * 0.6 * sway_mult

	# Apply new sway offset
	camera.rotation.x += sway_offset.x
	camera.rotation.y += sway_offset.y


## ── Hold Breath ──────────────────────────────────────────────────────────────

func _process_breath(delta: float) -> void:
	# Holding breath: sprint key while scoped
	var wants_hold := Input.is_action_pressed("sprint") and is_scoped and breath_remaining > 0.0 \
		and breath_exhausted_timer <= 0.0

	if wants_hold and not is_holding_breath:
		is_holding_breath = true
	elif not wants_hold and is_holding_breath:
		is_holding_breath = false

	if is_holding_breath:
		breath_remaining -= delta
		if breath_remaining <= 0.0:
			breath_remaining = 0.0
			is_holding_breath = false
			breath_exhausted_timer = breath_penalty_duration
	else:
		# Recharge breath
		breath_remaining = minf(breath_remaining + breath_recharge_rate * delta, breath_max)

	# Tick exhaustion penalty
	if breath_exhausted_timer > 0.0:
		breath_exhausted_timer -= delta


func get_breath_ratio() -> float:
	## Returns 0.0 (empty) to 1.0 (full) for HUD display.
	return breath_remaining / breath_max


## ── Actions ──────────────────────────────────────────────────────────────────

func try_shoot() -> void:
	if not can_shoot():
		return

	ammo_in_magazine -= 1
	_spawn_bullet()
	shot_fired.emit()

	# Enter bolt cycling
	state_timer = bolt_cycle_time
	_set_state(State.BOLT_CYCLING)


func _spawn_bullet() -> void:
	var bullet: CharacterBody3D = bullet_scene.instantiate()
	# Spawn at camera position, pointing forward
	bullet.global_position = camera.global_position
	bullet.direction = -camera.global_basis.z

	# Hipfire spread when not scoped
	if not is_scoped:
		bullet.spread_angle = deg_to_rad(hipfire_spread_deg)

	bullet.muzzle_velocity = muzzle_velocity
	bullet.bullet_gravity = bullet_gravity

	# Add to scene tree (not as child of player so it persists independently)
	get_tree().root.add_child(bullet)

	# Sound propagation — alert nearby enemies to the gunshot
	_propagate_gunshot_sound(camera.global_position)


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


## ── Sound propagation ────────────────────────────────────────────────────────

const GUNSHOT_LOUDNESS: float = 50.0  ## How far the sound carries

func _propagate_gunshot_sound(origin: Vector3) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("hear_sound"):
			enemy.hear_sound(origin, GUNSHOT_LOUDNESS)
