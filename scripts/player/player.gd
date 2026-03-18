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

## Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_ray: RayCast3D = $CeilingRay


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate body horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate head vertically, clamped to prevent flipping
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Horizontal speed (used for slide trigger)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	# Crouch / Slide
	var wants_crouch := Input.is_action_pressed("crouch")

	if wants_crouch and not is_crouching and not is_sliding:
		# Try to start a slide if moving fast enough and on floor
		if is_on_floor() and horizontal_speed >= slide_min_speed:
			is_sliding = true
			is_crouching = true
			slide_timer = slide_duration
			slide_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		else:
			is_crouching = true
	elif wants_crouch:
		# Already crouching or sliding — stay down
		pass
	elif not ceiling_ray.is_colliding():
		is_crouching = false
		is_sliding = false
	# else: stay crouched (ceiling above)

	# Slide update
	if is_sliding:
		slide_timer -= delta
		# Decelerate along slide direction
		horizontal_speed = maxf(horizontal_speed - slide_friction * delta, crouch_speed)
		velocity.x = slide_direction.x * horizontal_speed
		velocity.z = slide_direction.z * horizontal_speed

		# End slide when timer expires or speed drops to crouch speed
		if slide_timer <= 0.0 or horizontal_speed <= crouch_speed:
			is_sliding = false
			# Stay crouched if still holding crouch
			is_crouching = wants_crouch or ceiling_ray.is_colliding()

	# Smoothly adjust collision and head
	var target_height := CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var target_head_y := CROUCH_HEAD_Y if is_crouching else STAND_HEAD_Y
	var capsule: CapsuleShape3D = collision_shape.shape
	capsule.height = lerp(capsule.height, target_height, CROUCH_LERP_SPEED * delta)
	collision_shape.position.y = capsule.height / 2.0
	head.position.y = lerp(head.position.y, target_head_y, CROUCH_LERP_SPEED * delta)

	# Jump — cancels slide
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	if not is_sliding:
		# Sprint state (not while crouching)
		var is_sprinting := Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching
		var current_speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else move_speed)

		# WASD input
		var input_dir := Vector2.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_forward", "move_backward")

		# Direction relative to where player is facing
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
