class_name DestructibleRat
extends DestructibleMovingTarget
## Rat — medium-sized moving target that scurries between cover points.
## Spawns randomly in marked level blocks. Alternates run/pause.

enum SkinType { BROWN, GREY, BLACK }
enum State { RUNNING, PAUSING }

@export var skin: SkinType = SkinType.BROWN
@export var run_speed: float = 4.0
@export var pause_time_min: float = 1.5
@export var pause_time_max: float = 4.0
@export var wander_radius: float = 15.0  ## How far from spawn it can wander
@export var turn_speed: float = 6.0

var _state: State = State.PAUSING
var _target_pos: Vector3 = Vector3.ZERO
var _pause_timer: float = 0.0
var _origin: Vector3 = Vector3.ZERO
var _mesh_node: Node3D

const BODY_SIZE := Vector3(0.3, 0.15, 0.5)  ## Medium sized
const SKIN_COLORS: Dictionary = {
	SkinType.BROWN: Color(0.4, 0.28, 0.15),
	SkinType.GREY: Color(0.35, 0.35, 0.35),
	SkinType.BLACK: Color(0.15, 0.12, 0.1),
}


func _ready() -> void:
	super._ready()
	credit_reward = 50
	xp_reward = 20
	_origin = global_position
	_mesh_node = get_node_or_null("Mesh")
	_apply_skin()
	PaletteManager.bind_meshes(self, PaletteManager.SLOT_ACCENT_LOOT)
	_pick_new_target()
	_state = State.PAUSING
	_pause_timer = randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	match _state:
		State.RUNNING:
			_update_running(delta)
		State.PAUSING:
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_pick_new_target()
				_state = State.RUNNING


func _update_running(delta: float) -> void:
	var to_target := _target_pos - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist < 0.5:
		_state = State.PAUSING
		_pause_timer = randf_range(pause_time_min, pause_time_max)
		velocity = Vector3.ZERO
		return

	var dir := to_target.normalized()
	# Smooth turn toward target
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	var facing := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
	velocity = facing * run_speed

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()


func _pick_new_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(3.0, wander_radius)
	_target_pos = _origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _apply_skin() -> void:
	if not _mesh_node:
		return
	var body: MeshInstance3D = _mesh_node.get_node_or_null("Body")
	if not body:
		return

	# Ellipsoid-like shape using a scaled box
	var m := BoxMesh.new()
	m.size = BODY_SIZE
	body.mesh = m

	var mat := StandardMaterial3D.new()
	mat.albedo_color = SKIN_COLORS.get(skin, Color(0.4, 0.28, 0.15))
	body.material_override = mat
