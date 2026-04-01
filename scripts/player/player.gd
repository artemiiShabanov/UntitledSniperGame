extends CharacterBody3D

## Movement tuning
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var crouch_speed: float = 2.5

## Gravity
@export var gravity: float = 20.0

## Crouch settings
const STAND_HEIGHT: float = 1.8
const CROUCH_HEIGHT: float = 1.0
const STAND_HEAD_Y: float = 1.6
const CROUCH_HEAD_Y: float = 0.8
const CROUCH_LERP_SPEED: float = 10.0

## Slide settings
@export var slide_min_speed: float = 6.0
@export var slide_friction: float = 10.0
@export var slide_duration: float = 0.8

## State
var is_crouching: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO

## Footstep timing
const FOOTSTEP_WALK_INTERVAL: float = 0.5
const FOOTSTEP_SPRINT_INTERVAL: float = 0.33
const FOOTSTEP_CROUCH_INTERVAL: float = 0.7
const FOOTSTEP_CROUCH_VOLUME: float = -8.0  ## dB offset for crouch steps
const FOOTSTEP_SPRINT_VOLUME: float = 3.0   ## dB offset for sprint steps
const LANDING_VOLUME: float = 4.0            ## dB offset for landing thud
var _footstep_timer: float = 0.0
var _was_on_floor: bool = true

## Zipline state
var is_on_zipline: bool = false
var zipline_ref: Node3D = null
var zipline_progress: float = 0.0
var zipline_direction: float = 1.0

## Interaction
@export var interact_range: float = 3.0
var current_interactable: Interactable = null

## Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_ray: RayCast3D = $CeilingRay
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var weapon: Weapon = $Head/Camera3D/Weapon
@onready var hud = $HUD  ## PlayerHUD script on the HUD CanvasLayer


## Track whether mouse was captured before losing focus (for alt-tab restore)
var _was_mouse_captured: bool = false


func _ready() -> void:
	Input.use_accumulated_input = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	apply_modifications()
	weapon.state_changed.connect(_on_weapon_state_changed)
	weapon.shot_fired.connect(_on_shot_fired)
	weapon.ammo_type_changed.connect(_on_ammo_type_changed)
	RunManager.run_completed.connect(_on_run_completed)
	# Force initial HUD update (weapon._ready() fires before player connects)
	hud.set_scope_style(weapon.scope_style)
	hud.update_scope_visuals(weapon.is_scoped)
	hud.update_weapon_display(weapon)


func apply_modifications() -> void:
	## Apply mod stat overrides that affect the player (e.g. move_speed, sprint_speed).
	var multipliers: Dictionary = {}
	var loadout: Dictionary = SaveManager.get_equipped_loadout()
	for slot: String in loadout:
		var mod: RifleMod = ModRegistry.get_mod(loadout[slot])
		if not mod:
			continue
		for prop: String in mod.stat_overrides:
			if prop.ends_with("_mult"):
				var base_prop := prop.trim_suffix("_mult")
				multipliers[base_prop] = multipliers.get(base_prop, 1.0) * mod.stat_overrides[prop]
			elif prop in self:
				set(prop, mod.stat_overrides[prop])
	for prop: String in multipliers:
		if prop in self:
			set(prop, get(prop) * multipliers[prop])


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Release mouse when alt-tabbing so the OS cursor isn't trapped
			_was_mouse_captured = (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
			if _was_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Recapture mouse when returning, but only if it was captured before
			# and no UI panel is currently open (pause menu handles its own state)
			if _was_mouse_captured and not get_tree().paused:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_was_mouse_captured = false


func _input(event: InputEvent) -> void:
	if RunManager.is_dead:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)

	# Debug: T to simulate taking a hit
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_T:
		RunManager.take_hit()


func _physics_process(delta: float) -> void:
	# Keep scope overlay in sync every frame (weapon runs in _process, so
	# the authoritative is_scoped flag may change between state_changed signals)
	hud.update_scope_visuals(weapon.is_scoped)

	# Update breath meter
	hud.update_breath(
		weapon.get_breath_ratio(),
		weapon.breath_exhausted_timer > 0.0,
		weapon.is_scoped
	)

	if RunManager.is_dead:
		velocity = Vector3.ZERO
		return

	# Freeze movement during extraction — player can still look around
	if RunManager.game_state == RunManager.GameState.EXTRACTING:
		velocity = Vector3.ZERO
		_process_interaction()
		return

	if is_on_zipline:
		_process_zipline(delta)
		return

	_process_interaction()

	_apply_gravity(delta)
	_process_crouch_and_slide(delta)
	_update_collision_shape(delta)
	_process_jump()
	if not is_sliding:
		_process_movement()

	move_and_slide()

	# Landing sound
	if is_on_floor() and not _was_on_floor:
		AudioManager.play_sfx_2d_varied(&"footstep", 0.15, LANDING_VOLUME)
	_was_on_floor = is_on_floor()


## ── Input ────────────────────────────────────────────────────────────────────

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	var sens: float = SettingsManager.mouse_sensitivity * weapon.get_sensitivity_multiplier()
	rotate_y(-event.relative.x * sens)
	head.rotate_x(-event.relative.y * sens)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))


## ── Gravity ──────────────────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


## ── Crouch & Slide ───────────────────────────────────────────────────────────

func _process_crouch_and_slide(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	# Entering crouch or slide
	if wants_crouch and not is_crouching and not is_sliding:
		if is_on_floor() and horizontal_speed >= slide_min_speed:
			_start_slide(horizontal_speed)
		else:
			is_crouching = true
	elif not wants_crouch and not ceiling_ray.is_colliding():
		is_crouching = false
		is_sliding = false

	# Slide tick
	if is_sliding:
		_update_slide(delta, horizontal_speed, wants_crouch)


func _start_slide(horizontal_speed: float) -> void:
	is_sliding = true
	is_crouching = true
	slide_timer = slide_duration
	slide_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	AudioManager.play_sfx_2d_varied(&"slide", 0.1)


func _update_slide(delta: float, horizontal_speed: float, wants_crouch: bool) -> void:
	slide_timer -= delta
	horizontal_speed = maxf(horizontal_speed - slide_friction * delta, crouch_speed)
	velocity.x = slide_direction.x * horizontal_speed
	velocity.z = slide_direction.z * horizontal_speed

	if slide_timer <= 0.0 or horizontal_speed <= crouch_speed:
		is_sliding = false
		is_crouching = wants_crouch or ceiling_ray.is_colliding()


func _update_collision_shape(delta: float) -> void:
	var target_height := CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var target_head_y := CROUCH_HEAD_Y if is_crouching else STAND_HEAD_Y
	var capsule: CapsuleShape3D = collision_shape.shape
	capsule.height = lerp(capsule.height, target_height, CROUCH_LERP_SPEED * delta)
	collision_shape.position.y = capsule.height / 2.0
	head.position.y = lerp(head.position.y, target_head_y, CROUCH_LERP_SPEED * delta)


## ── Jump ─────────────────────────────────────────────────────────────────────

func _process_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity


## ── Movement ─────────────────────────────────────────────────────────────────

func _process_movement() -> void:
	var is_sprinting: bool = Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching and not weapon.is_scoped
	var current_speed: float = crouch_speed if is_crouching else (sprint_speed if is_sprinting else move_speed)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Footstep sounds
	_process_footsteps(direction, is_sprinting)


## ── Footsteps ───────────────────────────────────────────────────────────

func _process_footsteps(direction: Vector3, is_sprinting: bool) -> void:
	if not is_on_floor() or direction.is_zero_approx():
		_footstep_timer = 0.0
		return

	var interval: float
	var volume_offset: float = 0.0
	if is_crouching:
		interval = FOOTSTEP_CROUCH_INTERVAL
		volume_offset = FOOTSTEP_CROUCH_VOLUME
	elif is_sprinting:
		interval = FOOTSTEP_SPRINT_INTERVAL
		volume_offset = FOOTSTEP_SPRINT_VOLUME
	else:
		interval = FOOTSTEP_WALK_INTERVAL

	_footstep_timer += get_physics_process_delta_time()
	if _footstep_timer >= interval:
		_footstep_timer -= interval
		AudioManager.play_sfx_2d_varied(&"footstep", 0.2, volume_offset)


## ── Interaction ──────────────────────────────────────────────────────────────

func _process_interaction() -> void:
	# Check what the interaction ray is hitting
	var new_interactable: Interactable = null

	if interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		# Walk up the tree to find an Interactable parent (max 5 levels)
		var node := collider as Node
		var depth := 0
		while node and depth < 5:
			if node is Interactable:
				new_interactable = node
				break
			node = node.get_parent()
			depth += 1

	# Also check ziplines by proximity (they use line math, not collision shapes)
	if not new_interactable:
		var ziplines := get_tree().get_nodes_in_group("zipline")
		for zl in ziplines:
			if zl is Interactable:
				# Cheap broadphase: skip if too far from zipline origin
				var rough_dist_sq := global_position.distance_squared_to(zl.global_position)
				var max_range: float = zl.line_length + zl.attach_radius
				if rough_dist_sq > max_range * max_range:
					continue
				var result: Dictionary = zl.get_closest_point(global_position)
				if result.distance <= zl.attach_radius:
					new_interactable = zl
					break

	# Update prompt
	current_interactable = new_interactable
	if current_interactable:
		hud.update_interact_prompt(current_interactable.get_interact_prompt())
	elif _is_in_extraction_zone():
		hud.update_interact_prompt("Hold E to Extract")
	else:
		hud.hide_interact_prompt()

	# Fire interaction
	if current_interactable and Input.is_action_just_pressed("interact"):
		current_interactable.interact(self)


## ── Zipline ──────────────────────────────────────────────────────────────────

func _attach_to_zipline(zl: Node3D, start_progress: float) -> void:
	is_on_zipline = true
	zipline_ref = zl
	zipline_progress = start_progress
	velocity = Vector3.ZERO
	is_crouching = false
	is_sliding = false

	# Ride in the direction the player is looking
	var look_dir := -camera.global_basis.z
	var dot: float = look_dir.dot(zl.line_direction)
	zipline_direction = 1.0 if dot >= 0.0 else -1.0


func _process_zipline(delta: float) -> void:
	var zipline_speed_mult: float = SaveManager.get_skill_stat_bonus("zipline_speed_mult")
	var effective_speed: float = zipline_ref.speed * (zipline_speed_mult if zipline_speed_mult > 0.0 else 1.0)
	var speed_normalized: float = effective_speed / zipline_ref.line_length
	zipline_progress += zipline_direction * speed_normalized * delta
	zipline_progress = clampf(zipline_progress, 0.0, 1.0)

	global_position = zipline_ref.get_position_on_line(zipline_progress)

	var reached_end := (zipline_direction > 0.0 and zipline_progress >= 1.0) or \
		(zipline_direction < 0.0 and zipline_progress <= 0.0)

	if reached_end or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
		_detach_from_zipline()


func _detach_from_zipline() -> void:
	is_on_zipline = false
	velocity = Vector3(0, zipline_ref.detach_upward_boost, 0)
	velocity += zipline_ref.line_direction * zipline_direction * zipline_ref.speed * 0.3
	zipline_ref = null


## ── Weapon callbacks ─────────────────────────────────────────────────────────

func _on_weapon_state_changed(_new_state: int) -> void:
	hud.update_scope_visuals(weapon.is_scoped)
	hud.update_weapon_display(weapon)


func _on_shot_fired() -> void:
	hud.update_weapon_display(weapon)


func _on_ammo_type_changed(_ammo_type: AmmoType) -> void:
	hud.update_weapon_display(weapon)


## ── Extraction ──────────────────────────────────────────────────────────────

func _is_in_extraction_zone() -> bool:
	## Check if any active extraction zone has the player inside it.
	var zones := get_tree().get_nodes_in_group("extraction_zone")
	for zone in zones:
		if zone is ExtractionZone and zone.player_inside:
			return true
	return false


## ── Damage ───────────────────────────────────────────────────────────────────

func on_bullet_hit(_bullet: Node, _collision: KinematicCollision3D) -> void:
	## Called by Bullet when an enemy projectile hits the player.
	AudioManager.play_sfx_2d(&"hit_taken")
	RunManager.take_hit()


## ── Run callbacks ───────────────────────────────────────────────────────────

func _on_run_completed(success: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not success:
		AudioManager.play_sfx_2d(&"death")
	AudioManager.stop_ambient(0.5)
	AudioManager.stop_music(1.0)
	# Result screen handles display and return to hub
