class_name NpcBase
extends CharacterBody3D
## Base class for all neutral NPCs.
## Cycles through type-specific activities at ActivityPoints.
## Panics and flees on nearby gunfire. No combat capability.

## ── Signals ──────────────────────────────────────────────────────────────────

signal npc_killed(npc: NpcBase)

## ── Exports ──────────────────────────────────────────────────────────────────

@export var npc_type: NpcType
@export var show_debug: bool = false

## ── Enums ────────────────────────────────────────────────────────────────────

enum ActivityState { PERFORMING, TRAVELING }
enum PanicState { CALM, PANICKING }

## ── Constants ────────────────────────────────────────────────────────────────

const ARRIVE_DISTANCE: float = 0.5
const GRAVITY: float = 9.8

## ── State ────────────────────────────────────────────────────────────────────

var is_dead: bool = false

## Activity cycling
var activity_list: PackedStringArray = []  ## Set by subclass or from npc_type
var current_activity_index: int = 0
var activity_state: ActivityState = ActivityState.PERFORMING
var activity_timer: float = 0.0
var target_point: ActivityPoint = null

## Panic
var panic_state: PanicState = PanicState.CALM
var panic_timer: float = 0.0
var flee_direction: Vector3 = Vector3.ZERO

## Available activity points (set by BaseLevel after spawning)
var available_points: Array[ActivityPoint] = []

## ── Node references ──────────────────────────────────────────────────────────

@onready var mesh: Node3D = $Mesh
@onready var head_marker: Marker3D = $HeadMarker

## Visuals (delegated)
var _visuals: NpcVisuals


func _ready() -> void:
	add_to_group("npc")

	# Load activity list from type resource
	if npc_type:
		activity_list = npc_type.get_activity_list()

	# Create visual system
	_visuals = NpcVisuals.new()
	add_child(_visuals)
	_visuals.setup(self)

	# Start first activity
	_start_current_activity()


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		move_and_slide()

	# Panic overrides normal activity
	if panic_state == PanicState.PANICKING:
		_update_panic(delta)
	else:
		_update_activity(delta)

	_visuals.update_visuals()


## ── Activity Cycling ────────────────────────────────────────────────────────

func _update_activity(delta: float) -> void:
	match activity_state:
		ActivityState.PERFORMING:
			activity_timer -= delta
			if activity_timer <= 0.0:
				_advance_activity()
		ActivityState.TRAVELING:
			_move_toward_target(delta)


func _start_current_activity() -> void:
	if activity_list.is_empty() or not npc_type:
		return

	var activity_name: String = activity_list[current_activity_index]
	var duration: float = npc_type.activity_durations.get(activity_name, 5.0)
	activity_timer = duration
	activity_state = ActivityState.PERFORMING

	# Face the activity point direction
	if target_point:
		rotation.y = deg_to_rad(target_point.facing_direction)


func _advance_activity() -> void:
	if activity_list.is_empty():
		return

	# Move to next activity in cycle
	current_activity_index = (current_activity_index + 1) % activity_list.size()
	var next_activity_name: String = activity_list[current_activity_index]

	# Find a matching activity point
	target_point = _find_activity_point(next_activity_name)
	if target_point:
		activity_state = ActivityState.TRAVELING
	else:
		# No point found — just perform in place
		_start_current_activity()


func _move_toward_target(delta: float) -> void:
	if not target_point:
		_start_current_activity()
		return

	var to_target := target_point.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist < ARRIVE_DISTANCE:
		velocity = Vector3.ZERO
		_start_current_activity()
		return

	var dir := to_target.normalized()
	_face_direction(dir)
	velocity.x = dir.x * npc_type.move_speed
	velocity.z = dir.z * npc_type.move_speed
	move_and_slide()


func _find_activity_point(activity_name: String) -> ActivityPoint:
	## Finds a random activity point matching the given activity name.
	var matching: Array[ActivityPoint] = []
	for point in available_points:
		if point.get_activity_name() == activity_name:
			matching.append(point)

	if matching.is_empty():
		return null

	return matching[randi() % matching.size()]


func _find_nearest_activity_point() -> ActivityPoint:
	## Finds the nearest activity point matching the current activity.
	if activity_list.is_empty():
		return null

	var activity_name: String = activity_list[current_activity_index]
	var best: ActivityPoint = null
	var best_dist := INF

	for point in available_points:
		if point.get_activity_name() == activity_name:
			var d := global_position.distance_squared_to(point.global_position)
			if d < best_dist:
				best_dist = d
				best = point

	# Fallback: any point
	if not best:
		for point in available_points:
			var d := global_position.distance_squared_to(point.global_position)
			if d < best_dist:
				best_dist = d
				best = point

	return best


## ── Panic / Flee ────────────────────────────────────────────────────────────

func hear_sound(origin: Vector3, loudness: float) -> void:
	if is_dead:
		return

	var distance := global_position.distance_to(origin)
	var effect := loudness / maxf(distance, 1.0)
	var threshold: float = npc_type.panic_threshold if npc_type else 0.3

	if effect > threshold:
		_enter_panic(origin)


func _enter_panic(threat_origin: Vector3) -> void:
	if panic_state == PanicState.PANICKING:
		# Already panicking — refresh timer and update flee direction
		panic_timer = npc_type.panic_duration if npc_type else 6.0
		flee_direction = (global_position - threat_origin).normalized()
		flee_direction.y = 0.0
		return

	panic_state = PanicState.PANICKING
	panic_timer = npc_type.panic_duration if npc_type else 6.0
	activity_state = ActivityState.PERFORMING  # Reset activity state

	# Flee away from threat
	flee_direction = (global_position - threat_origin).normalized()
	flee_direction.y = 0.0
	if flee_direction.length_squared() < 0.001:
		flee_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()


func _update_panic(delta: float) -> void:
	panic_timer -= delta

	if panic_timer <= 0.0:
		_exit_panic()
		return

	# Flee movement
	var speed: float = npc_type.panic_flee_speed if npc_type else 3.5
	_face_direction(flee_direction)
	velocity.x = flee_direction.x * speed
	velocity.z = flee_direction.z * speed
	move_and_slide()

	# If hitting a wall, pick a new flee direction
	if is_on_wall():
		var wall_normal := get_wall_normal()
		flee_direction = (flee_direction + wall_normal).normalized()
		flee_direction.y = 0.0


func _exit_panic() -> void:
	panic_state = PanicState.CALM
	velocity = Vector3.ZERO

	# Resume activity from nearest matching point
	target_point = _find_nearest_activity_point()
	if target_point:
		activity_state = ActivityState.TRAVELING
	else:
		_start_current_activity()


## ── Damage / Death ──────────────────────────────────────────────────────────

func on_bullet_hit(_bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_dead:
		return
	_die()


func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	npc_killed.emit(self)

	# Report penalty to RunManager
	var penalty: int = npc_type.kill_penalty if npc_type else 100
	RunManager.record_npc_kill(penalty)

	# Visual death — distinct color from enemy death
	_visuals.on_death()
	_on_death()


func _on_death() -> void:
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.5)  ## Blueish-grey, distinct from enemy red
		for child in mesh.get_children():
			if child is MeshInstance3D:
				child.material_override = mat
			elif child is CSGShape3D:
				child.material = mat

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	var tree := get_tree()
	if tree:
		var timer := tree.create_timer(3.0)
		timer.timeout.connect(func(): if is_instance_valid(self): queue_free())


## ── Helpers ─────────────────────────────────────────────────────────────────

func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		rotation.y = atan2(-dir.x, -dir.z)
