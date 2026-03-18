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

## Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_ray: RayCast3D = $CeilingRay


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)

	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()


func _physics_process(delta: float) -> void:
	if is_on_zipline:
		_process_zipline(delta)
		return

	if Input.is_action_just_pressed("interact"):
		_try_attach_zipline()

	_apply_gravity(delta)
	_process_crouch_and_slide(delta)
	_update_collision_shape(delta)
	_process_jump()
	if not is_sliding:
		_process_movement()

	move_and_slide()


## ── Input ────────────────────────────────────────────────────────────────────

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	head.rotate_x(-event.relative.y * mouse_sensitivity)
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
	var is_sprinting := Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching
	var current_speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else move_speed)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)


## ── Zipline ──────────────────────────────────────────────────────────────────

func _try_attach_zipline() -> void:
	var ziplines := get_tree().get_nodes_in_group("zipline")
	var best_zl: Node3D = null
	var best_dist: float = INF
	var best_progress: float = 0.0

	for zl in ziplines:
		var result: Dictionary = zl.get_closest_point(global_position)
		if result.distance < zl.attach_radius and result.distance < best_dist:
			best_zl = zl
			best_dist = result.distance
			best_progress = result.progress

	if best_zl:
		_attach_to_zipline(best_zl, best_progress)


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
