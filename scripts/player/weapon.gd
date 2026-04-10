class_name Weapon
extends Node3D
## Sniper rifle weapon controller.
## Manages scope zoom, bolt-action cycling, sway, breath, and a fixed bullet pool.

## ── Enums ────────────────────────────────────────────────────────────────────

enum State { IDLE, AIMING, BOLT_CYCLING }

## ── Exports ──────────────────────────────────────────────────────────────────

## Scope
@export var default_fov: float = 70.0
@export var scoped_fov: float = 15.0
@export var scope_lerp_speed: float = 12.0
const SWAY_REFERENCE_FOV: float = 30.0

## Bolt action
const DEFAULT_BOLT_CYCLE_TIME: float = 1.2
@export var bolt_cycle_time: float = 1.2

## Sway
@export var sway_amplitude: float = 0.003
@export var sway_speed: float = 1.5
@export var sway_penalty_mult: float = 2.5

## Hold breath
@export var breath_max: float = 3.0
@export var breath_recharge_rate: float = 0.75
@export var breath_penalty_duration: float = 1.5
@export var breath_sway_mult: float = 0.1

## Hipfire
@export var hipfire_spread_deg: float = 2.0

## Bullet
@export var bullet_scene: PackedScene = preload("res://scenes/projectile/bullet.tscn")
@export var muzzle_velocity: float = 300.0
@export var bullet_gravity: float = 9.8

## Sound
@export var gunshot_loudness: float = 50.0
@export var impact_loudness: float = 20.0

## ── Constants ───────────────────────────────────────────────────────────────

const BASE_BULLETS: int = 30

## ── State ────────────────────────────────────────────────────────────────────

var state: State = State.IDLE
var is_scoped: bool = false
var state_timer: float = 0.0

## Mod specials
var _suppressed: bool = false
var _continuous_bolt: bool = false
var _variable_zoom: bool = false
var _variable_zoom_min: float = 6.0
var _variable_zoom_max: float = 30.0
var scope_style: int = 0
var _was_scoped_before_shot: bool = false

## Sway & breath
var sway_time: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO
var breath_remaining: float = 3.0
var is_holding_breath: bool = false
var breath_exhausted_timer: float = 0.0
var _heartbeat_timer: float = 0.0
const HEARTBEAT_INTERVAL: float = 0.8

## Ammo — single pool, no types, no reload
var bullets_remaining: int = BASE_BULLETS

## ── Signals ──────────────────────────────────────────────────────────────────

signal shot_fired
signal bolt_cycled
signal state_changed(new_state: State)
signal bullets_changed(remaining: int)

## ── Node references ──────────────────────────────────────────────────────────

@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CharacterBody3D = owner


func _ready() -> void:
	assert(camera != null, "Weapon must be a child of Camera3D")
	apply_modifications()
	breath_remaining = breath_max
	state_changed.emit(state)


## ── Modifications ────────────────────────────────────────────────────────────

func apply_modifications() -> void:
	# Read procedural mods from SaveManager equipped loadout.
	var equipped: Dictionary = SaveManager.get_equipped_loadout()
	for slot_name: String in equipped:
		var mod_index: int = equipped[slot_name]
		var mod_data: Dictionary = SaveManager.get_mod_at(mod_index)
		if mod_data.is_empty():
			continue
		var stats: Dictionary = mod_data.get("stats", {})
		_apply_mod_stats(slot_name, stats)

	# Skill bonuses (after mods so they stack)
	var breath_bonus: float = SaveManager.get_skill_stat_bonus("breath_max")
	if breath_bonus > 0.0:
		breath_max += breath_bonus

	var bolt_mult: float = SaveManager.get_skill_stat_bonus("bolt_cycle_mult")
	if bolt_mult != 0.0:
		bolt_cycle_time = maxf(bolt_cycle_time * (1.0 + bolt_mult), 0.2)

	var bonus_bullets: int = int(SaveManager.get_skill_stat_bonus("bonus_bullets"))
	bullets_remaining = BASE_BULLETS + bonus_bullets


func _apply_mod_stats(slot_name: String, stats: Dictionary) -> void:
	match slot_name:
		"barrel":
			if stats.has("velocity"):
				muzzle_velocity *= stats["velocity"]
			if stats.has("accuracy"):
				hipfire_spread_deg /= stats["accuracy"]
		"stock":
			if stats.has("sway_reduction"):
				sway_amplitude *= (1.0 - stats["sway_reduction"])
			if stats.has("move_speed") and player:
				# move_speed is applied by player reading from weapon
				pass
		"bolt":
			if stats.has("cycle_time"):
				bolt_cycle_time = stats["cycle_time"]
			if stats.get("stay_scoped", false):
				_continuous_bolt = true
		"magazine":
			if stats.has("capacity"):
				bullets_remaining += int(stats["capacity"])
			# headshot_damage is read at kill-time by the damage system
		"scope":
			if stats.has("fov"):
				scoped_fov = stats["fov"]
			if stats.has("clarity"):
				# Clarity reduces scoped sway
				sway_amplitude *= (1.0 - stats["clarity"] * 0.3)
			if stats.get("variable_zoom", false):
				_variable_zoom = true


func _process(delta: float) -> void:
	_process_state_timer(delta)
	_process_scope(delta)
	_process_sway(delta)
	_process_breath(delta)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
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
		if state == State.BOLT_CYCLING:
			var bolt_pitch: float = DEFAULT_BOLT_CYCLE_TIME / bolt_cycle_time
			AudioManager.play_sfx_2d_pitched(&"rifle_bolt", bolt_pitch)
			bolt_cycled.emit()
			if not _continuous_bolt and _was_scoped_before_shot and Input.is_action_pressed("zoom"):
				is_scoped = true
			_set_state(State.AIMING if is_scoped else State.IDLE)


func can_shoot() -> bool:
	return state in [State.IDLE, State.AIMING] and bullets_remaining > 0


func is_busy() -> bool:
	return state == State.BOLT_CYCLING


## ── Scope ────────────────────────────────────────────────────────────────────

func _process_scope(delta: float) -> void:
	var scope_blocked := state == State.BOLT_CYCLING and not _continuous_bolt
	var wants_scope := Input.is_action_pressed("zoom") and not scope_blocked

	if wants_scope and not is_scoped:
		is_scoped = true
		AudioManager.play_sfx_2d(&"scope_in")
		AudioManager.play_sfx_2d_varied(&"scope_zoom", 0.1)
		if state == State.IDLE:
			_set_state(State.AIMING)
		else:
			state_changed.emit(state)
	elif not wants_scope and is_scoped:
		is_scoped = false
		AudioManager.play_sfx_2d(&"scope_out")
		AudioManager.play_sfx_2d_varied(&"scope_zoom", 0.1)
		if state == State.AIMING:
			_set_state(State.IDLE)
		else:
			state_changed.emit(state)

	# Variable zoom: scroll wheel adjusts scoped_fov
	if _variable_zoom and is_scoped:
		if Input.is_action_just_pressed("ammo_next"):
			scoped_fov = clampf(scoped_fov - 2.0, _variable_zoom_min, _variable_zoom_max)
		elif Input.is_action_just_pressed("ammo_prev"):
			scoped_fov = clampf(scoped_fov + 2.0, _variable_zoom_min, _variable_zoom_max)

	var target_fov := scoped_fov if is_scoped else default_fov
	camera.fov = lerp(camera.fov, target_fov, scope_lerp_speed * delta)


func get_sensitivity_multiplier() -> float:
	if not camera:
		return 1.0
	return camera.fov / default_fov


## ── Input ────────────────────────────────────────────────────────────────────

func _process_input() -> void:
	if Input.is_action_just_pressed("shoot"):
		try_shoot()


## ── Sway ─────────────────────────────────────────────────────────────────────

func _process_sway(delta: float) -> void:
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

	var zoom_sway := sqrt(SWAY_REFERENCE_FOV / maxf(camera.fov, 1.0))
	sway_offset.x = sin(sway_time * 1.1) * sway_amplitude * sway_mult * zoom_sway
	sway_offset.y = sin(sway_time * 0.7) * sway_amplitude * 0.6 * sway_mult * zoom_sway

	camera.rotation.x += sway_offset.x
	camera.rotation.y += sway_offset.y


## ── Hold Breath ──────────────────────────────────────────────────────────────

func _process_breath(delta: float) -> void:
	var wants_hold := Input.is_action_pressed("sprint") and is_scoped and breath_remaining > 0.0 \
		and breath_exhausted_timer <= 0.0

	if wants_hold and not is_holding_breath:
		is_holding_breath = true
		_heartbeat_timer = 0.0
		AudioManager.play_sfx_2d(&"breath_hold")
	elif not wants_hold and is_holding_breath:
		is_holding_breath = false
		_heartbeat_timer = 0.0
		AudioManager.play_sfx_2d_varied(&"breath_exhale", 0.1)

	if is_holding_breath:
		breath_remaining -= delta
		_heartbeat_timer += delta
		if _heartbeat_timer >= HEARTBEAT_INTERVAL:
			_heartbeat_timer -= HEARTBEAT_INTERVAL
			AudioManager.play_sfx_2d_varied(&"heartbeat", 0.05, -3.0)
		if breath_remaining <= 0.0:
			breath_remaining = 0.0
			is_holding_breath = false
			_heartbeat_timer = 0.0
			breath_exhausted_timer = breath_penalty_duration
			AudioManager.play_sfx_2d_varied(&"breath_exhale", 0.1, 3.0)
	else:
		breath_remaining = minf(breath_remaining + breath_recharge_rate * delta, breath_max)

	if breath_exhausted_timer > 0.0:
		breath_exhausted_timer -= delta


func get_breath_ratio() -> float:
	return breath_remaining / breath_max


## ── Actions ──────────────────────────────────────────────────────────────────

func try_shoot() -> void:
	if not can_shoot():
		if bullets_remaining <= 0 and state in [State.IDLE, State.AIMING]:
			AudioManager.play_sfx_2d(&"rifle_dry")
		return

	bullets_remaining -= 1
	bullets_changed.emit(bullets_remaining)
	_spawn_bullet()
	shot_fired.emit()
	RunManager.record_shot_fired()

	_was_scoped_before_shot = is_scoped
	if not _continuous_bolt and is_scoped:
		is_scoped = false

	state_timer = bolt_cycle_time
	_set_state(State.BOLT_CYCLING)


func _spawn_bullet() -> void:
	var bullet: Bullet = bullet_scene.instantiate()

	var spawn_pos := camera.global_position
	var spawn_dir := -camera.global_basis.z

	bullet.direction = spawn_dir

	if not is_scoped:
		bullet.spread_angle = deg_to_rad(hipfire_spread_deg)

	bullet.muzzle_velocity = muzzle_velocity
	bullet.bullet_gravity = bullet_gravity
	bullet.impact_loudness = impact_loudness

	get_tree().root.add_child(bullet)
	bullet.global_position = spawn_pos

	VFXFactory.spawn_muzzle_flash(spawn_pos + spawn_dir * 0.3, spawn_dir, false)
	var fire_sound: StringName = &"rifle_fire_suppressed" if _suppressed else &"rifle_fire"
	AudioManager.play_sfx(fire_sound, spawn_pos)

	_propagate_gunshot_sound(spawn_pos)


## ── Sound propagation ────────────────────────────────────────────────────────

func _propagate_gunshot_sound(origin: Vector3) -> void:
	# Warriors don't use stealth detection — sound propagation is a no-op for now.
	# Kept as a hook for future use.
	pass
