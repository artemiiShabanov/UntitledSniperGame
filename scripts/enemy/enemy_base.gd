class_name EnemyBase
extends CharacterBody3D
## Base class for all enemy snipers.
## Handles alert state machine, line-of-sight detection, shooting, and damage.

## ── Enums ────────────────────────────────────────────────────────────────────

enum AlertState { UNAWARE, SUSPICIOUS, ALERT, SEARCHING }

## ── Signals ──────────────────────────────────────────────────────────────────

signal alert_state_changed(new_state: AlertState)
signal enemy_killed(enemy: EnemyBase, headshot: bool)

## ── Exports: Debug ───────────────────────────────────────────────────────────

@export_group("Debug")
@export var show_debug: bool = true  ## Toggle FOV cone and state indicator

## ── Exports: Detection ───────────────────────────────────────────────────────

@export_group("Detection")
@export var fov_degrees: float = 90.0  ## Half-angle field of view cone
@export var max_sight_range: float = 80.0
@export var suspicion_rate: float = 0.4  ## Per second while player is in LOS
@export var suspicion_decay: float = 0.2  ## Per second when player not visible
@export var alert_threshold: float = 1.0  ## Suspicion level to become ALERT
@export var search_duration: float = 8.0  ## How long to search before returning to UNAWARE
@export var search_scan_speed: float = 0.8  ## Radians per second to scan left/right
@export var search_scan_angle: float = 45.0  ## Degrees to scan each side of last known dir

## ── Exports: Combat ──────────────────────────────────────────────────────────

@export_group("Combat")
@export var health: float = 100.0
@export var reaction_time: float = 1.5  ## Seconds after becoming ALERT before first shot
@export var fire_interval: float = 2.5  ## Seconds between shots when ALERT
@export var accuracy: float = 0.7  ## 0-1, higher = less spread
@export var inaccuracy_deg: float = 5.0  ## Max spread in degrees at accuracy=0
@export var enemy_bullet_speed: float = 200.0  ## Slower than player bullets
@export var bullet_scene: PackedScene = preload("res://scenes/projectile/bullet.tscn")
@export var shot_damage: float = 1.0
@export var headshot_multiplier: float = 2.0

## ── Exports: Rewards ─────────────────────────────────────────────────────────

@export_group("Rewards")
@export var credit_reward: int = 50
@export var xp_reward: int = 25

## ── State ────────────────────────────────────────────────────────────────────

var alert_state: AlertState = AlertState.UNAWARE
var suspicion: float = 0.0
var is_dead: bool = false
var player: Node3D = null

## Detection
var can_see_player: bool = false
var last_known_player_pos: Vector3 = Vector3.ZERO

## Combat timers
var reaction_timer: float = 0.0
var fire_timer: float = 0.0
var search_timer: float = 0.0

## Search scanning
var _search_base_yaw: float = 0.0  ## Y rotation toward last known position
var _search_scan_progress: float = 0.0  ## Oscillates -1 to 1
var _search_scan_dir: float = 1.0  ## Current scan direction

## ── Node references ──────────────────────────────────────────────────────────

@onready var sight_ray: RayCast3D = $SightRay
@onready var head_marker: Marker3D = $HeadMarker  ## For headshot detection
@onready var mesh: Node3D = $Mesh

## Debug visualization
var _debug_mesh_instance: MeshInstance3D
var _debug_immediate_mesh: ImmediateMesh
var _debug_material: StandardMaterial3D
var _state_indicator: MeshInstance3D
var _state_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemy")
	_find_player()
	if show_debug:
		_setup_debug_visuals()


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	if not player:
		_find_player()
		if not player:
			return

	_update_line_of_sight()
	_update_alert_state(delta)
	_update_combat(delta)

	if show_debug:
		_update_debug_visuals()


## ── Line of Sight ────────────────────────────────────────────────────────────

func _update_line_of_sight() -> void:
	can_see_player = false

	if not player:
		return

	var eye_pos := global_position + Vector3.UP * 1.5  ## Approximate eye height
	var to_player := _get_player_head_pos() - eye_pos
	var distance := to_player.length()

	# Range check
	if distance > max_sight_range:
		return

	# FOV check — angle between forward direction and direction to player
	var forward := -global_basis.z
	var angle := forward.angle_to(to_player.normalized())
	if rad_to_deg(angle) > fov_degrees:
		return

	# Raycast occlusion check
	sight_ray.global_position = eye_pos
	sight_ray.target_position = sight_ray.to_local(eye_pos + to_player)
	sight_ray.force_raycast_update()

	if sight_ray.is_colliding():
		var collider := sight_ray.get_collider()
		if collider and collider.is_in_group("player"):
			can_see_player = true
			last_known_player_pos = player.global_position


## ── Alert State Machine ──────────────────────────────────────────────────────

func _update_alert_state(delta: float) -> void:
	match alert_state:
		AlertState.UNAWARE:
			if can_see_player:
				suspicion += suspicion_rate * delta
				if suspicion >= alert_threshold:
					_set_alert_state(AlertState.ALERT)
				elif suspicion >= alert_threshold * 0.3:
					_set_alert_state(AlertState.SUSPICIOUS)
			else:
				suspicion = maxf(suspicion - suspicion_decay * delta, 0.0)

		AlertState.SUSPICIOUS:
			if can_see_player:
				suspicion += suspicion_rate * delta
				if suspicion >= alert_threshold:
					_set_alert_state(AlertState.ALERT)
			else:
				suspicion -= suspicion_decay * delta
				if suspicion <= 0.0:
					suspicion = 0.0
					_set_alert_state(AlertState.UNAWARE)

		AlertState.ALERT:
			if can_see_player:
				last_known_player_pos = player.global_position
			else:
				# Lost sight — start searching
				_set_alert_state(AlertState.SEARCHING)

		AlertState.SEARCHING:
			search_timer -= delta
			if can_see_player:
				_set_alert_state(AlertState.ALERT)
			elif search_timer <= 0.0:
				suspicion = 0.0
				_set_alert_state(AlertState.UNAWARE)
			else:
				_update_search_scan(delta)


func _set_alert_state(new_state: AlertState) -> void:
	if alert_state == new_state:
		return

	alert_state = new_state
	alert_state_changed.emit(new_state)

	match new_state:
		AlertState.ALERT:
			reaction_timer = reaction_time
			fire_timer = 0.0
			_face_player()
		AlertState.SEARCHING:
			search_timer = search_duration
			# Face last known position, then begin scanning
			_face_position(last_known_player_pos)
			_search_base_yaw = rotation.y
			_search_scan_progress = 0.0
			_search_scan_dir = 1.0


## ── Combat ───────────────────────────────────────────────────────────────────

func _update_combat(delta: float) -> void:
	if alert_state != AlertState.ALERT:
		return

	_face_player()

	# Wait for reaction time before shooting
	if reaction_timer > 0.0:
		reaction_timer -= delta
		return

	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire_at_player()
		fire_timer = fire_interval


func _fire_at_player() -> void:
	if not can_see_player or not player:
		return

	var eye_pos := global_position + Vector3.UP * 1.5
	var target := _get_player_head_pos()
	var aim_dir := (target - eye_pos).normalized()

	# Spawn projectile bullet
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.global_position = eye_pos
	bullet.direction = aim_dir
	bullet.muzzle_velocity = enemy_bullet_speed
	bullet.is_enemy_bullet = true
	bullet.damage = shot_damage

	# Accuracy affects spread — lower accuracy = more spread
	var spread := deg_to_rad(inaccuracy_deg * (1.0 - accuracy))
	bullet.spread_angle = spread

	get_tree().root.add_child(bullet)


func _face_player() -> void:
	if not player:
		return
	var target_pos := last_known_player_pos if not can_see_player else player.global_position
	_face_position(target_pos)


func _face_position(target: Vector3) -> void:
	var look_pos := Vector3(target.x, global_position.y, target.z)
	if look_pos.distance_to(global_position) > 0.1:
		look_at(look_pos, Vector3.UP)


func _update_search_scan(delta: float) -> void:
	## Oscillate rotation left/right around the last known direction
	_search_scan_progress += _search_scan_dir * search_scan_speed * delta

	# Reverse direction at scan limits
	var max_progress := deg_to_rad(search_scan_angle)
	if _search_scan_progress > max_progress:
		_search_scan_progress = max_progress
		_search_scan_dir = -1.0
	elif _search_scan_progress < -max_progress:
		_search_scan_progress = -max_progress
		_search_scan_dir = 1.0

	rotation.y = _search_base_yaw + _search_scan_progress


## ── Sound Reaction ───────────────────────────────────────────────────────────

func hear_sound(origin: Vector3, loudness: float) -> void:
	## Called when a loud event (gunshot, bullet impact) occurs nearby.
	if is_dead:
		return

	var distance := global_position.distance_to(origin)
	var effect := loudness / maxf(distance, 1.0)

	if alert_state == AlertState.UNAWARE or alert_state == AlertState.SUSPICIOUS:
		suspicion += effect
		last_known_player_pos = origin
		if suspicion >= alert_threshold:
			_set_alert_state(AlertState.ALERT)
		elif suspicion >= alert_threshold * 0.3 and alert_state == AlertState.UNAWARE:
			_set_alert_state(AlertState.SUSPICIOUS)
	elif alert_state == AlertState.SEARCHING:
		last_known_player_pos = origin
		# Re-alert if sound is strong enough
		if effect > 0.3:
			_set_alert_state(AlertState.ALERT)


## ── Damage ───────────────────────────────────────────────────────────────────

func on_bullet_hit(bullet: Bullet, collision: KinematicCollision3D) -> void:
	if is_dead:
		return

	var hit_point := collision.get_position()
	var is_headshot := _check_headshot(hit_point)
	var dmg := bullet.damage
	if is_headshot:
		dmg *= headshot_multiplier

	health -= dmg

	# Getting shot immediately alerts
	if alert_state != AlertState.ALERT:
		suspicion = alert_threshold
		last_known_player_pos = bullet.global_position
		_set_alert_state(AlertState.ALERT)

	if health <= 0.0:
		_die(is_headshot)


func _check_headshot(hit_point: Vector3) -> bool:
	if not head_marker:
		return false
	# Headshot if hit point is within 0.3m of head marker
	return hit_point.distance_to(head_marker.global_position) < 0.3


func _die(headshot: bool) -> void:
	is_dead = true
	enemy_killed.emit(self, headshot)

	# Hide debug visuals
	if _debug_mesh_instance:
		_debug_mesh_instance.visible = false
	if _state_indicator:
		_state_indicator.visible = false

	# Report to RunManager
	RunManager.record_shot_hit()
	RunManager.record_kill(headshot)
	RunManager.add_run_credits(credit_reward)
	RunManager.add_run_xp(xp_reward)

	# Visual death — turn red and disable collision
	_on_death()


## Override in subclasses for custom death behavior
func _on_death() -> void:
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.1, 0.1)
		for child in mesh.get_children():
			if child is MeshInstance3D:
				child.material_override = mat
			elif child is CSGShape3D:
				child.material = mat

	# Disable collision after a frame to avoid physics issues
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Remove after delay
	var timer := get_tree().create_timer(3.0)
	await timer.timeout
	queue_free()


## ── Debug Visualization ──────────────────────────────────────────────────────

const STATE_COLORS := {
	AlertState.UNAWARE: Color(0.2, 0.8, 0.2, 0.8),    ## Green
	AlertState.SUSPICIOUS: Color(1.0, 0.8, 0.0, 0.8),  ## Yellow
	AlertState.ALERT: Color(1.0, 0.1, 0.1, 0.8),       ## Red
	AlertState.SEARCHING: Color(1.0, 0.5, 0.0, 0.8),   ## Orange
}

func _setup_debug_visuals() -> void:
	# FOV cone mesh
	_debug_immediate_mesh = ImmediateMesh.new()
	_debug_mesh_instance = MeshInstance3D.new()
	_debug_mesh_instance.mesh = _debug_immediate_mesh
	_debug_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_debug_material = StandardMaterial3D.new()
	_debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_material.albedo_color = Color(0.2, 0.8, 0.2, 0.15)
	_debug_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_debug_material.no_depth_test = true

	add_child(_debug_mesh_instance)

	# State indicator sphere above head
	_state_indicator = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	_state_indicator.mesh = sphere
	_state_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_state_indicator.position = Vector3(0, 2.3, 0)

	_state_mat = StandardMaterial3D.new()
	_state_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_mat.albedo_color = STATE_COLORS[AlertState.UNAWARE]
	_state_indicator.material_override = _state_mat

	add_child(_state_indicator)


func _update_debug_visuals() -> void:
	if not _debug_immediate_mesh:
		return

	# Update state indicator color
	_state_mat.albedo_color = STATE_COLORS.get(alert_state, Color.WHITE)

	# Update FOV cone color based on state
	var cone_color: Color = STATE_COLORS.get(alert_state, Color.GREEN)
	cone_color.a = 0.1 if alert_state == AlertState.UNAWARE else 0.2
	_debug_material.albedo_color = cone_color

	# Rebuild FOV cone
	_debug_immediate_mesh.clear_surfaces()
	_debug_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _debug_material)

	var eye_offset := Vector3(0, 1.5, 0)
	var cone_length: float = minf(max_sight_range, 20.0)  ## Cap visual length
	var half_angle := deg_to_rad(fov_degrees)
	var segments := 16

	for i in range(segments):
		var angle_a := TAU * float(i) / float(segments)
		var angle_b := TAU * float(i + 1) / float(segments)

		var dir_a := Vector3(
			sin(half_angle) * cos(angle_a),
			sin(half_angle) * sin(angle_a),
			-cos(half_angle)
		) * cone_length
		var dir_b := Vector3(
			sin(half_angle) * cos(angle_b),
			sin(half_angle) * sin(angle_b),
			-cos(half_angle)
		) * cone_length

		# Triangle from eye to edge
		_debug_immediate_mesh.surface_add_vertex(eye_offset)
		_debug_immediate_mesh.surface_add_vertex(eye_offset + dir_a)
		_debug_immediate_mesh.surface_add_vertex(eye_offset + dir_b)

	_debug_immediate_mesh.surface_end()


## ── Helpers ──────────────────────────────────────────────────────────────────

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _get_player_head_pos() -> Vector3:
	if not player:
		return Vector3.ZERO
	# Player head is at $Head position
	if player.has_node("Head"):
		return player.get_node("Head").global_position
	return player.global_position + Vector3.UP * 1.6
