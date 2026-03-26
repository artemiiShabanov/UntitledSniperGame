class_name Weapon
extends Node3D
## Sniper rifle weapon controller.
## Manages scope zoom, bolt-action cycling, reload, inspect, sway, and breath.
## Ammo type management is delegated to AmmoManager.

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

## Sway & breath
var sway_time: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO
var breath_remaining: float = 3.0
var is_holding_breath: bool = false
var breath_exhausted_timer: float = 0.0

## Ammo manager (owns magazine, reserves, type switching)
var ammo: AmmoManager = AmmoManager.new()

## ── Convenience accessors (preserve external API) ───────────────────────────
## player.gd and player_hud.gd read these — forwarded to AmmoManager.

var ammo_in_magazine: int:
	get: return ammo.magazine
	set(v): ammo.magazine = v

var ammo_reserve: int:
	get: return ammo.reserve
	set(v): ammo.reserve = v

## ── Signals ──────────────────────────────────────────────────────────────────

signal shot_fired
signal reload_complete
signal bolt_cycled
signal state_changed(new_state: State)
signal ammo_type_changed(ammo_type: AmmoType)

## ── Node references ──────────────────────────────────────────────────────────

@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CharacterBody3D = owner


func _ready() -> void:
	assert(camera != null, "Weapon must be a child of Camera3D")
	apply_modifications()
	breath_remaining = breath_max
	ammo.load_types(magazine_size)
	ammo.ammo_type_changed.connect(func(t: AmmoType):
		ammo_type_changed.emit(t)
		state_changed.emit(state)  # Update HUD
	)
	# Auto-load first magazine so player starts with ammo ready
	ammo.do_reload()
	# Emit initial state so HUD displays correctly from frame 1
	state_changed.emit(state)


## ── Modifications ────────────────────────────────────────────────────────────

func apply_modifications() -> void:
	# Apply equipped mods
	var loadout: Dictionary = SaveManager.get_equipped_loadout()
	for slot: String in loadout:
		var mod: RifleMod = ModRegistry.get_mod(loadout[slot])
		if not mod:
			continue
		for prop: String in mod.stat_overrides:
			if prop in self:
				set(prop, mod.stat_overrides[prop])

	# Apply skill bonuses (after mods so they stack)
	var breath_bonus: float = SaveManager.get_skill_stat_bonus("breath_max")
	if breath_bonus > 0.0:
		breath_max += breath_bonus

	var reload_mult: float = SaveManager.get_skill_stat_bonus("reload_time_mult")
	if reload_mult > 0.0:
		reload_time *= reload_mult


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
				AudioManager.play_sfx_2d(&"rifle_bolt")
				bolt_cycled.emit()
				# Auto-reload if magazine is empty
				if not ammo.has_ammo() and ammo.can_reload():
					state_timer = reload_time
					_set_state(State.RELOADING)
				else:
					_set_state(State.AIMING if is_scoped else State.IDLE)
			State.RELOADING:
				_finish_reload()
			State.INSPECTING:
				_set_state(State.IDLE)


func can_shoot() -> bool:
	return state in [State.IDLE, State.AIMING] and ammo.has_ammo()


func can_reload() -> bool:
	return state in [State.IDLE, State.AIMING] and ammo.can_reload()


func is_busy() -> bool:
	return state in [State.BOLT_CYCLING, State.RELOADING, State.INSPECTING]


func _cancel_inspect() -> void:
	if state == State.INSPECTING:
		state_timer = 0.0
		_set_state(State.IDLE)


## ── Scope ────────────────────────────────────────────────────────────────────

func _process_scope(delta: float) -> void:
	var scope_blocked := state in [State.RELOADING, State.INSPECTING]
	var wants_scope := Input.is_action_pressed("zoom") and not scope_blocked

	if wants_scope and not is_scoped:
		is_scoped = true
		AudioManager.play_sfx_2d(&"scope_in")
		if state == State.IDLE:
			_set_state(State.AIMING)
	elif not wants_scope and is_scoped:
		is_scoped = false
		AudioManager.play_sfx_2d(&"scope_out")
		if state == State.AIMING:
			_set_state(State.IDLE)

	var target_fov := scoped_fov if is_scoped else default_fov
	camera.fov = lerp(camera.fov, target_fov, scope_lerp_speed * delta)


func get_sensitivity_multiplier() -> float:
	if is_scoped:
		return scoped_sensitivity_mult
	return 1.0


## ── Ammo Type (forwarded to AmmoManager) ───────────────────────────────────

func get_current_ammo_type() -> AmmoType:
	return ammo.get_current_type()


func cycle_ammo_type(direction: int = 1) -> void:
	if is_busy():
		return
	ammo.cycle_type(direction)
	AudioManager.play_sfx_2d(&"ammo_switch")


func select_ammo_type(index: int) -> void:
	if is_busy():
		return
	ammo.select_type(index)
	AudioManager.play_sfx_2d(&"ammo_switch")


## ── Input ────────────────────────────────────────────────────────────────────

func _process_input() -> void:
	if state == State.INSPECTING:
		if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("zoom") \
				or Input.is_action_just_pressed("reload"):
			_cancel_inspect()

	if Input.is_action_just_pressed("shoot"):
		try_shoot()

	if Input.is_action_just_pressed("reload"):
		try_reload()

	if Input.is_action_just_pressed("inspect") and state == State.IDLE:
		_start_inspect()

	# Cycle ammo type — mouse wheel
	if Input.is_action_just_pressed("ammo_next"):
		cycle_ammo_type(1)
	elif Input.is_action_just_pressed("ammo_prev"):
		cycle_ammo_type(-1)

	# Direct ammo selection — number keys 1-5
	if Input.is_action_just_pressed("ammo_1"):
		select_ammo_type(0)
	elif Input.is_action_just_pressed("ammo_2"):
		select_ammo_type(1)
	elif Input.is_action_just_pressed("ammo_3"):
		select_ammo_type(2)
	elif Input.is_action_just_pressed("ammo_4"):
		select_ammo_type(3)
	elif Input.is_action_just_pressed("ammo_5"):
		select_ammo_type(4)


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

	sway_offset.x = sin(sway_time * 1.1) * sway_amplitude * sway_mult
	sway_offset.y = sin(sway_time * 0.7) * sway_amplitude * 0.6 * sway_mult

	camera.rotation.x += sway_offset.x
	camera.rotation.y += sway_offset.y


## ── Hold Breath ──────────────────────────────────────────────────────────────

func _process_breath(delta: float) -> void:
	var wants_hold := Input.is_action_pressed("sprint") and is_scoped and breath_remaining > 0.0 \
		and breath_exhausted_timer <= 0.0

	if wants_hold and not is_holding_breath:
		is_holding_breath = true
		AudioManager.play_sfx_2d(&"breath_hold")
	elif not wants_hold and is_holding_breath:
		is_holding_breath = false

	if is_holding_breath:
		breath_remaining -= delta
		if breath_remaining <= 0.0:
			breath_remaining = 0.0
			is_holding_breath = false
			breath_exhausted_timer = breath_penalty_duration
	else:
		breath_remaining = minf(breath_remaining + breath_recharge_rate * delta, breath_max)

	if breath_exhausted_timer > 0.0:
		breath_exhausted_timer -= delta


func get_breath_ratio() -> float:
	return breath_remaining / breath_max


## ── Actions ──────────────────────────────────────────────────────────────────

func try_shoot() -> void:
	if not can_shoot():
		if not ammo.has_ammo() and state in [State.IDLE, State.AIMING]:
			AudioManager.play_sfx_2d(&"rifle_dry")
		return

	ammo.consume_round()
	_spawn_bullet()
	shot_fired.emit()
	RunManager.record_shot_fired()

	state_timer = bolt_cycle_time
	_set_state(State.BOLT_CYCLING)


func _spawn_bullet() -> void:
	var bullet: Bullet = bullet_scene.instantiate()

	var spawn_pos := camera.global_position
	var spawn_dir := -camera.global_basis.z

	bullet.direction = spawn_dir

	if not is_scoped:
		bullet.spread_angle = deg_to_rad(hipfire_spread_deg)

	# Delegate ammo property application to AmmoManager
	ammo.configure_bullet(bullet, muzzle_velocity, bullet_gravity)

	get_tree().root.add_child(bullet)
	bullet.global_position = spawn_pos

	# Muzzle flash VFX + audio
	VFXFactory.spawn_muzzle_flash(spawn_pos + spawn_dir * 0.3, spawn_dir, false)
	AudioManager.play_sfx(&"rifle_fire", spawn_pos)

	_propagate_gunshot_sound(spawn_pos)


func try_reload() -> void:
	if not can_reload():
		return

	is_scoped = false
	state_timer = reload_time
	_set_state(State.RELOADING)
	AudioManager.play_sfx_2d(&"rifle_reload")


func _finish_reload() -> void:
	ammo.do_reload()
	reload_complete.emit()
	_set_state(State.IDLE)


func _start_inspect() -> void:
	is_scoped = false
	state_timer = inspect_duration
	_set_state(State.INSPECTING)


## ── Sound propagation ────────────────────────────────────────────────────────

const GUNSHOT_LOUDNESS: float = 50.0

func _propagate_gunshot_sound(origin: Vector3) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("hear_sound"):
			enemy.hear_sound(origin, GUNSHOT_LOUDNESS)
	var npcs := get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.has_method("hear_sound"):
			npc.hear_sound(origin, GUNSHOT_LOUDNESS)
