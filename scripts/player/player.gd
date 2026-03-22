extends CharacterBody3D

## Movement tuning
@export var mouse_sensitivity: float = 0.002
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
@onready var interact_prompt: Label = $HUD/InteractPrompt
@onready var crosshair: Control = $HUD/Crosshair
@onready var scope_overlay: Control = $HUD/ScopeOverlay
@onready var weapon_state_label: Label = $HUD/WeaponState
@onready var lives_label: Label = $HUD/LivesLabel
@onready var hit_flash: ColorRect = $HUD/HitFlash
@onready var death_overlay: ColorRect = $HUD/DeathOverlay
@onready var breath_meter: Control = $HUD/BreathMeter
@onready var run_timer_label: Label = $HUD/RunTimer
@onready var threat_phase_label: Label = $HUD/ThreatPhase

## Hit flash
var hit_flash_alpha: float = 0.0
const HIT_FLASH_FADE_SPEED: float = 3.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon.state_changed.connect(_on_weapon_state_changed)
	weapon.shot_fired.connect(_on_shot_fired)
	RunManager.life_lost.connect(_on_life_lost)
	RunManager.run_failed.connect(_on_run_failed)
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(_on_run_completed)
	RunManager.run_timer_updated.connect(_on_run_timer_updated)
	RunManager.threat_phase_changed.connect(_on_threat_phase_changed)
	_update_lives_display()
	run_timer_label.visible = false
	threat_phase_label.visible = false


func _input(event: InputEvent) -> void:
	if RunManager.is_dead:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)

	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()

	# Debug: T to simulate taking a hit
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		RunManager.take_hit()


func _physics_process(delta: float) -> void:
	# Fade hit flash
	if hit_flash_alpha > 0.0:
		hit_flash_alpha = maxf(hit_flash_alpha - HIT_FLASH_FADE_SPEED * delta, 0.0)
		hit_flash.color.a = hit_flash_alpha

	# Update breath meter
	breath_meter.update_breath(
		weapon.get_breath_ratio(),
		weapon.breath_exhausted_timer > 0.0,
		weapon.is_scoped
	)

	if RunManager.is_dead:
		velocity = Vector3.ZERO
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


## ── Input ────────────────────────────────────────────────────────────────────

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	var sens := mouse_sensitivity * weapon.get_sensitivity_multiplier()
	rotate_y(-event.relative.x * sens)
	head.rotate_x(-event.relative.y * sens)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	var is_sprinting := Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching and not weapon.is_scoped
	var current_speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else move_speed)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)


## ── Interaction ──────────────────────────────────────────────────────────────

func _process_interaction() -> void:
	# Check what the interaction ray is hitting
	var new_interactable: Interactable = null

	if interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		# Walk up the tree to find an Interactable parent
		var node := collider as Node
		while node:
			if node is Interactable:
				new_interactable = node
				break
			node = node.get_parent()

	# Also check ziplines by proximity (they use line math, not collision shapes)
	if not new_interactable:
		var ziplines := get_tree().get_nodes_in_group("zipline")
		for zl in ziplines:
			if zl is Interactable:
				var result: Dictionary = zl.get_closest_point(global_position)
				if result.distance <= zl.attach_radius:
					new_interactable = zl
					break

	# Update prompt
	current_interactable = new_interactable
	if current_interactable:
		interact_prompt.text = current_interactable.get_interact_prompt()
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false

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
	var speed_normalized: float = zipline_ref.speed / zipline_ref.line_length
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
	# Toggle crosshair / scope overlay
	var scoped := weapon.is_scoped
	crosshair.visible = not scoped
	scope_overlay.visible = scoped
	if scoped:
		scope_overlay.queue_redraw()
	_update_weapon_display()


func _on_shot_fired() -> void:
	_update_weapon_display()


func _update_weapon_display() -> void:
	const STATE_NAMES := ["IDLE", "AIMING", "BOLT_CYCLING", "RELOADING", "INSPECTING"]
	weapon_state_label.text = "%s | %d/%d | $%d" % [
		STATE_NAMES[weapon.state],
		weapon.ammo_in_magazine,
		weapon.ammo_reserve,
		RunManager.get_run_credits(),
	]


## ── Damage ───────────────────────────────────────────────────────────────────

func on_bullet_hit(_bullet: Node, _collision: KinematicCollision3D) -> void:
	## Called by Bullet when an enemy projectile hits the player.
	RunManager.take_hit()


## ── Lives callbacks ──────────────────────────────────────────────────────────

func _on_life_lost(lives_remaining: int) -> void:
	_update_lives_display()
	# Red flash
	hit_flash_alpha = 0.4
	hit_flash.color = Color(1, 0, 0, hit_flash_alpha)


func _on_run_started() -> void:
	run_timer_label.visible = true
	threat_phase_label.visible = true
	death_overlay.visible = false
	_update_lives_display()
	_update_threat_display()


func _on_run_failed() -> void:
	_update_lives_display()
	death_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_run_completed(_success: bool) -> void:
	run_timer_label.visible = false
	threat_phase_label.visible = false
	# For now, auto-return to hub after a delay (result screen will replace this later)
	await get_tree().create_timer(3.0).timeout
	RunManager.go_to_hub()


## ── Run timer ────────────────────────────────────────────────────────────────

func _on_run_timer_updated(time_left: float) -> void:
	run_timer_label.visible = RunManager.game_state == RunManager.GameState.IN_RUN or \
		RunManager.game_state == RunManager.GameState.EXTRACTING
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	run_timer_label.text = "%d:%02d" % [minutes, seconds]
	# Turn red when under 30 seconds
	if time_left <= 30.0:
		run_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		run_timer_label.remove_theme_color_override("font_color")


func _on_threat_phase_changed(_phase: RunManager.ThreatPhase) -> void:
	_update_threat_display()


func _update_threat_display() -> void:
	var phase_name := RunManager.get_threat_phase_name()
	threat_phase_label.text = "THREAT: %s" % phase_name
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			threat_phase_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		RunManager.ThreatPhase.MID:
			threat_phase_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		RunManager.ThreatPhase.LATE:
			threat_phase_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))


func _update_lives_display() -> void:
	var hearts := ""
	for i in range(RunManager.max_lives):
		if i < RunManager.lives:
			hearts += "♥ "
		else:
			hearts += "♡ "
	lives_label.text = hearts.strip_edges()
