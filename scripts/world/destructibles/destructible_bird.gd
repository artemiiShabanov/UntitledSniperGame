class_name DestructibleBird
extends CharacterBody3D
## Bird — small flying target. Alternates between sitting, eating, and flying.
## Hard to hit in flight, easier when perched. High reward.

signal target_destroyed(target: DestructibleBird)

enum SkinType { BROWN, WHITE, BLACK }
enum State { SITTING, EATING, TAKING_OFF, FLYING, LANDING }

@export var skin: SkinType = SkinType.BROWN
@export var credit_reward: int = 80
@export var xp_reward: int = 30
@export var fly_speed: float = 6.0
@export var fly_height: float = 8.0
@export var wander_radius: float = 20.0
@export var sit_time_min: float = 3.0
@export var sit_time_max: float = 8.0
@export var eat_time_min: float = 2.0
@export var eat_time_max: float = 5.0
@export var fly_time_min: float = 4.0
@export var fly_time_max: float = 8.0
@export var turn_speed: float = 4.0

var is_destroyed: bool = false
var _state: State = State.SITTING
var _state_timer: float = 0.0
var _target_pos: Vector3 = Vector3.ZERO
var _origin: Vector3 = Vector3.ZERO
var _ground_y: float = 0.0
var _mesh_node: Node3D

const BODY_SIZE := Vector3(0.15, 0.1, 0.2)
const SKIN_COLORS: Dictionary = {
	SkinType.BROWN: Color(0.45, 0.3, 0.15),
	SkinType.WHITE: Color(0.85, 0.85, 0.8),
	SkinType.BLACK: Color(0.1, 0.1, 0.12),
}


func _ready() -> void:
	add_to_group("destructible")
	_origin = global_position
	_ground_y = global_position.y
	_mesh_node = get_node_or_null("Mesh")
	_apply_skin()
	PaletteManager.bind_meshes(self, PaletteManager.SLOT_ACCENT_LOOT)
	_enter_state(State.SITTING)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	_state_timer -= delta

	match _state:
		State.SITTING:
			if _state_timer <= 0.0:
				# Randomly choose to eat or fly
				if randf() < 0.4:
					_enter_state(State.EATING)
				else:
					_enter_state(State.TAKING_OFF)

		State.EATING:
			_update_eating(delta)
			if _state_timer <= 0.0:
				if randf() < 0.5:
					_enter_state(State.SITTING)
				else:
					_enter_state(State.TAKING_OFF)

		State.TAKING_OFF:
			_update_vertical(delta, _ground_y + fly_height)
			if global_position.y >= _ground_y + fly_height - 0.5:
				_enter_state(State.FLYING)

		State.FLYING:
			_update_flying(delta)
			if _state_timer <= 0.0:
				_enter_state(State.LANDING)

		State.LANDING:
			_update_vertical(delta, _ground_y)
			if global_position.y <= _ground_y + 0.3:
				global_position.y = _ground_y
				velocity = Vector3.ZERO
				_enter_state(State.SITTING)


func _enter_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.SITTING:
			velocity = Vector3.ZERO
			_state_timer = randf_range(sit_time_min, sit_time_max)
		State.EATING:
			velocity = Vector3.ZERO
			_state_timer = randf_range(eat_time_min, eat_time_max)
		State.TAKING_OFF:
			_pick_fly_target()
			_state_timer = 5.0  ## Max takeoff time
		State.FLYING:
			_state_timer = randf_range(fly_time_min, fly_time_max)
		State.LANDING:
			_state_timer = 5.0  ## Max landing time


func _update_eating(delta: float) -> void:
	# Bob head up and down (slight Y oscillation on mesh)
	if _mesh_node:
		var bob := sin(Time.get_ticks_msec() * 0.008) * 0.03
		_mesh_node.position.y = bob


func _update_vertical(delta: float, target_y: float) -> void:
	# Move toward fly target horizontally while ascending/descending
	var to_target := Vector3(_target_pos.x - global_position.x, 0, _target_pos.z - global_position.z)
	if to_target.length() > 1.0:
		var dir := to_target.normalized()
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
		var facing := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		velocity.x = facing.x * fly_speed * 0.5
		velocity.z = facing.z * fly_speed * 0.5
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = sign(target_y - global_position.y) * fly_speed * 0.8
	move_and_slide()


func _update_flying(delta: float) -> void:
	var to_target := Vector3(_target_pos.x - global_position.x, 0, _target_pos.z - global_position.z)
	var dist := to_target.length()

	if dist < 2.0:
		_pick_fly_target()

	var dir := to_target.normalized()
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	var facing := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
	velocity.x = facing.x * fly_speed
	velocity.z = facing.z * fly_speed

	# Gentle altitude wobble
	var target_y := _ground_y + fly_height + sin(Time.get_ticks_msec() * 0.002) * 1.0
	velocity.y = (target_y - global_position.y) * 2.0

	move_and_slide()


func _pick_fly_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(5.0, wander_radius)
	_target_pos = _origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _apply_skin() -> void:
	if not _mesh_node:
		return
	var body: MeshInstance3D = _mesh_node.get_node_or_null("Body")
	if not body:
		return

	var m := BoxMesh.new()
	m.size = BODY_SIZE
	body.mesh = m

	var mat := StandardMaterial3D.new()
	mat.albedo_color = SKIN_COLORS.get(skin, Color(0.45, 0.3, 0.15))
	body.material_override = mat


func on_bullet_hit(_bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_destroyed:
		return
	_destroy()


func _destroy() -> void:
	is_destroyed = true
	velocity = Vector3.ZERO
	target_destroyed.emit(self)

	RunManager.record_target_destroyed(credit_reward, xp_reward)
	AudioManager.play_sfx(&"target_destroyed", global_position)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	VFXFactory.spawn_death_effect(self, false)
