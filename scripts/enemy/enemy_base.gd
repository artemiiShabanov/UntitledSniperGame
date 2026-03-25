class_name EnemyBase
extends CharacterBody3D
## Base class for all enemy snipers.
## Handles alert state machine, line-of-sight detection, shooting, and damage.
## Visual systems (glint, laser, debug) are delegated to EnemyVisuals.

## ── Enums ────────────────────────────────────────────────────────────────────

enum AlertState { UNAWARE, SUSPICIOUS, ALERT, SEARCHING }

## ── Signals ──────────────────────────────────────────────────────────────────

signal alert_state_changed(new_state: AlertState)
signal enemy_killed(enemy: EnemyBase, headshot: bool)

## ── Exports: Debug ───────────────────────────────────────────────────────────

@export_group("Debug")
@export var show_debug: bool = false  ## Toggle FOV cone and state indicator

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
@export var is_armored: bool = false    ## Reduces non-AP damage by 75%
@export var armor_reduction: float = 0.25  ## Damage multiplier when armored and hit by non-AP

## ── Exports: Scope Glint ───────────────────────────────────────────────────

@export_group("Scope Glint")
@export var glint_enabled: bool = true
@export var glint_color: Color = Color(1.0, 0.95, 0.7, 1.0)
@export var glint_max_energy: float = 3.0
@export var glint_pulse_speed: float = 3.0
@export var glint_suspicious_flash: bool = true
@export var glint_suspicious_threshold: float = 0.7
@export var laser_enabled: bool = true
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 0.6)
@export var laser_length: float = 3.0
@export var laser_width: float = 0.02

## ── Exports: Behavior ───────────────────────────────────────────────────────

@export_group("Behavior")
@export var initial_behavior: String = "default"
@export var patrol_points: Array[Vector3] = []
@export var patrol_speed: float = 1.5
@export var patrol_wait_time: float = 3.0
@export var scan_speed: float = 0.3
@export var scan_angle: float = 60.0

## ── Exports: Rewards ─────────────────────────────────────────────────────────

@export_group("Rewards")
@export var credit_reward: int = 50
@export var xp_reward: int = 25

## ── Constants ────────────────────────────────────────────────────────────────

const EYE_HEIGHT: float = 1.5
const HEADSHOT_RADIUS: float = 0.3
const PLAYER_HEAD_FALLBACK_HEIGHT: float = 1.6

## ── State ────────────────────────────────────────────────────────────────────

var alert_state: AlertState = AlertState.UNAWARE
var suspicion: float = 0.0
var is_dead: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var player: Node3D = null

## Detection
var can_see_player: bool = false
var last_known_player_pos: Vector3 = Vector3.ZERO

## Combat timers
var reaction_timer: float = 0.0
var fire_timer: float = 0.0
var search_timer: float = 0.0
var _last_hit_was_headshot: bool = false

## Search scanning
var _search_base_yaw: float = 0.0
var _search_scan_progress: float = 0.0
var _search_scan_dir: float = 1.0

## Behavior (UNAWARE state)
var _behavior_base_yaw: float = 0.0
var _behavior_scan_progress: float = 0.0
var _behavior_scan_dir: float = 1.0
var _patrol_index: int = 0
var _patrol_waiting: bool = false
var _patrol_wait_timer: float = 0.0

## ── Node references ──────────────────────────────────────────────────────────

@onready var sight_ray: RayCast3D = $SightRay
@onready var head_marker: Marker3D = $HeadMarker
@onready var mesh: Node3D = $Mesh

## Visuals (delegated)
var _visuals: EnemyVisuals

## Stun material backup
var _original_materials: Dictionary = {}


func _ready() -> void:
	add_to_group("enemy")
	_find_player()
	_behavior_base_yaw = rotation.y

	# Create and setup visual systems
	_visuals = EnemyVisuals.new()
	add_child(_visuals)
	_visuals.setup(self)

	# Palette: color all meshes as hostile
	PaletteManager.bind_meshes(self, &"accent_hostile")


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Stun handling — frozen, skip all behavior
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			_update_stun_visual(false)
		_visuals.update_visuals(delta)
		return

	if not player:
		_find_player()
		if not player:
			return

	_update_line_of_sight()
	_update_alert_state(delta)
	_update_behavior(delta)
	_update_combat(delta)
	_visuals.update_visuals(delta)


## ── Line of Sight ────────────────────────────────────────────────────────────

func _get_effective_sight_range() -> float:
	var level := _get_base_level()
	if level:
		return max_sight_range * level.visibility_multiplier
	return max_sight_range


func _get_base_level() -> BaseLevel:
	var node := get_parent()
	while node:
		if node is BaseLevel:
			return node
		node = node.get_parent()
	return null


func _update_line_of_sight() -> void:
	can_see_player = false

	if not player:
		return

	var eye_pos := global_position + Vector3.UP * EYE_HEIGHT
	var to_player := _get_player_head_pos() - eye_pos
	var distance := to_player.length()

	if distance > _get_effective_sight_range():
		return

	var forward := -global_basis.z
	var angle := forward.angle_to(to_player.normalized())
	if rad_to_deg(angle) > fov_degrees:
		return

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
		AlertState.UNAWARE:
			velocity = Vector3.ZERO
			if initial_behavior == "patrol" and not patrol_points.is_empty():
				_patrol_index = _find_closest_patrol_point()
				_patrol_waiting = false
		AlertState.ALERT:
			reaction_timer = reaction_time
			fire_timer = 0.0
			velocity = Vector3.ZERO
			_face_player()
		AlertState.SEARCHING:
			search_timer = search_duration
			velocity = Vector3.ZERO
			_face_position(last_known_player_pos)
			_search_base_yaw = rotation.y
			_search_scan_progress = 0.0
			_search_scan_dir = 1.0


## ── Behavior (UNAWARE idle actions) ──────────────────────────────────────────

func _update_behavior(delta: float) -> void:
	if alert_state != AlertState.UNAWARE:
		return

	match initial_behavior:
		"scanning":
			_update_behavior_scan(delta)
		"patrol":
			_update_behavior_patrol(delta)


func _update_behavior_scan(delta: float) -> void:
	_behavior_scan_progress += _behavior_scan_dir * scan_speed * delta
	var max_progress := deg_to_rad(scan_angle)
	if _behavior_scan_progress > max_progress:
		_behavior_scan_progress = max_progress
		_behavior_scan_dir = -1.0
	elif _behavior_scan_progress < -max_progress:
		_behavior_scan_progress = -max_progress
		_behavior_scan_dir = 1.0
	rotation.y = _behavior_base_yaw + _behavior_scan_progress


func _update_behavior_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	if _patrol_waiting:
		_patrol_wait_timer -= delta
		if _patrol_wait_timer <= 0.0:
			_patrol_waiting = false
			_patrol_index = (_patrol_index + 1) % patrol_points.size()
		return

	var target := patrol_points[_patrol_index]
	var to_target := target - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist < 0.5:
		_patrol_waiting = true
		_patrol_wait_timer = patrol_wait_time
		return

	var dir := to_target.normalized()
	_face_direction(dir)
	velocity = dir * patrol_speed
	move_and_slide()


func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		rotation.y = atan2(-dir.x, -dir.z)


func _find_closest_patrol_point() -> int:
	var closest := 0
	var closest_dist := INF
	for i in patrol_points.size():
		var d := global_position.distance_squared_to(patrol_points[i])
		if d < closest_dist:
			closest_dist = d
			closest = i
	return closest


## ── Combat ───────────────────────────────────────────────────────────────────

func _update_combat(delta: float) -> void:
	if alert_state != AlertState.ALERT:
		return

	_face_player()

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

	var eye_pos := global_position + Vector3.UP * EYE_HEIGHT
	var target := _get_player_head_pos()
	var aim_dir := (target - eye_pos).normalized()

	var bullet: Bullet = bullet_scene.instantiate()
	bullet.direction = aim_dir
	bullet.muzzle_velocity = enemy_bullet_speed
	bullet.is_enemy_bullet = true
	bullet.damage = shot_damage

	var spread := deg_to_rad(inaccuracy_deg * (1.0 - accuracy))
	bullet.spread_angle = spread

	get_tree().root.add_child(bullet)
	bullet.global_position = eye_pos

	# Muzzle flash
	VFXFactory.spawn_muzzle_flash(eye_pos, aim_dir, true)


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
	_search_scan_progress += _search_scan_dir * search_scan_speed * delta

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
		if effect > 0.3:
			_set_alert_state(AlertState.ALERT)


## ── Damage ───────────────────────────────────────────────────────────────────

func on_bullet_hit(bullet: Bullet, collision: KinematicCollision3D) -> void:
	if is_dead:
		return

	# Shock ammo — stun instead of damage
	if bullet.is_shock:
		stun(bullet.stun_duration)
		return

	var hit_point := collision.get_position()
	var hit_normal := collision.get_normal()
	var is_headshot := _check_headshot(hit_point)
	var dmg := bullet.damage

	# Headshot-specific VFX (regular impact already spawned by bullet)
	if is_headshot:
		VFXFactory.spawn_hit_impact(hit_point, hit_normal, true)

	# Armor reduces damage unless AP or headshot
	if is_armored and not bullet.penetration and not is_headshot:
		dmg *= armor_reduction

	if is_headshot:
		dmg *= headshot_multiplier

	health -= dmg

	# Getting shot immediately alerts
	if alert_state != AlertState.ALERT:
		suspicion = alert_threshold
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			last_known_player_pos = players[0].global_position
		_set_alert_state(AlertState.ALERT)

	_last_hit_was_headshot = is_headshot
	if health <= 0.0:
		_die(is_headshot)


func _check_headshot(hit_point: Vector3) -> bool:
	if not head_marker:
		return false
	return hit_point.distance_to(head_marker.global_position) < HEADSHOT_RADIUS


## ── Stun ────────────────────────────────────────────────────────────────────

func stun(duration: float) -> void:
	if is_dead:
		return
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	_update_stun_visual(true)

	if alert_state == AlertState.UNAWARE or alert_state == AlertState.SUSPICIOUS:
		suspicion = alert_threshold
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			last_known_player_pos = players[0].global_position


func _update_stun_visual(stunned: bool) -> void:
	if not mesh:
		return
	if stunned:
		_original_materials.clear()
		for child in mesh.get_children():
			if child is MeshInstance3D:
				_original_materials[child] = child.material_override
			elif child is CSGShape3D:
				_original_materials[child] = child.material
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.6, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.6, 1.0)
		mat.emission_energy_multiplier = 1.5
		for child in mesh.get_children():
			if child is MeshInstance3D:
				child.material_override = mat
			elif child is CSGShape3D:
				child.material = mat
	else:
		for child in _original_materials:
			if is_instance_valid(child):
				if child is MeshInstance3D:
					child.material_override = _original_materials[child]
				elif child is CSGShape3D:
					child.material = _original_materials[child]
		_original_materials.clear()


func _die(headshot: bool) -> void:
	is_dead = true
	enemy_killed.emit(self, headshot)

	# Hide visuals
	_visuals.on_death()

	# Report to RunManager with distance + headshot bonuses
	RunManager.record_shot_hit()
	RunManager.record_kill_with_bonus(self, headshot, credit_reward, xp_reward)

	# Visual death — turn red and disable collision
	_on_death()


## Override in subclasses for custom death behavior
func _on_death() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# VFX handles tilt, fade, and cleanup
	VFXFactory.spawn_death_effect(self, _last_hit_was_headshot)


## ── Helpers ──────────────────────────────────────────────────────────────────

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _get_player_head_pos() -> Vector3:
	if not player:
		return Vector3.ZERO
	if player.has_node("Head"):
		return player.get_node("Head").global_position
	return player.global_position + Vector3.UP * PLAYER_HEAD_FALLBACK_HEIGHT
