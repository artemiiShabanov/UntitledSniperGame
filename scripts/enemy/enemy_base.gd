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
@export var is_armored: bool = false    ## Reduces non-AP damage by 75%
@export var armor_reduction: float = 0.25  ## Damage multiplier when armored and hit by non-AP

## ── Exports: Scope Glint ───────────────────────────────────────────────────

@export_group("Scope Glint")
@export var glint_enabled: bool = true  ## Whether this enemy shows scope glint
@export var glint_color: Color = Color(1.0, 0.95, 0.7, 1.0)  ## Warm white
@export var glint_max_energy: float = 3.0  ## Peak OmniLight brightness
@export var glint_pulse_speed: float = 3.0  ## Pulse oscillation speed
@export var glint_suspicious_flash: bool = true  ## Flash during late SUSPICIOUS
@export var glint_suspicious_threshold: float = 0.7  ## Fraction of alert_threshold
@export var laser_enabled: bool = true  ## Short laser showing aim direction
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 0.6)  ## Red
@export var laser_length: float = 3.0  ## Meters before full fade
@export var laser_width: float = 0.02  ## Beam thickness

## ── Exports: Behavior ───────────────────────────────────────────────────────

@export_group("Behavior")
@export var initial_behavior: String = "default"  ## "default", "idle", "scanning", "patrol"
@export var patrol_points: Array[Vector3] = []  ## World-space waypoints for patrol behavior
@export var patrol_speed: float = 1.5  ## Walk speed between patrol points
@export var patrol_wait_time: float = 3.0  ## Pause at each patrol point
@export var scan_speed: float = 0.3  ## Slower than search scan for idle scanning
@export var scan_angle: float = 60.0  ## Degrees to scan each side

## ── Exports: Rewards ─────────────────────────────────────────────────────────

@export_group("Rewards")
@export var credit_reward: int = 50
@export var xp_reward: int = 25

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

## Search scanning
var _search_base_yaw: float = 0.0  ## Y rotation toward last known position
var _search_scan_progress: float = 0.0  ## Oscillates -1 to 1
var _search_scan_dir: float = 1.0  ## Current scan direction

## Behavior (UNAWARE state)
var _behavior_base_yaw: float = 0.0  ## Starting facing direction
var _behavior_scan_progress: float = 0.0
var _behavior_scan_dir: float = 1.0
var _patrol_index: int = 0  ## Current waypoint index
var _patrol_waiting: bool = false
var _patrol_wait_timer: float = 0.0

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

## Scope glint
var _glint_sprite: Sprite3D
var _glint_light: OmniLight3D
var _glint_material: StandardMaterial3D
var _glint_active: bool = false
var _glint_time: float = 0.0

## Laser sight
var _laser_mesh_instance: MeshInstance3D
var _laser_immediate_mesh: ImmediateMesh
var _laser_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemy")
	_find_player()
	_behavior_base_yaw = rotation.y
	if show_debug:
		_setup_debug_visuals()
	if glint_enabled:
		_setup_glint()
	if laser_enabled:
		_setup_laser()


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Stun handling — frozen, skip all behavior
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			_update_stun_visual(false)
		if show_debug:
			_update_debug_visuals()
		_update_laser()
		return

	if not player:
		_find_player()
		if not player:
			return

	_update_line_of_sight()
	_update_alert_state(delta)
	_update_behavior(delta)
	_update_combat(delta)
	_update_glint(delta)
	_update_laser()

	if show_debug:
		_update_debug_visuals()


## ── Line of Sight ────────────────────────────────────────────────────────────

func _get_effective_sight_range() -> float:
	## Returns sight range adjusted for weather/time visibility.
	var level := _get_base_level()
	if level:
		return max_sight_range * level.visibility_multiplier
	return max_sight_range


func _get_base_level() -> BaseLevel:
	## Walk up the tree to find the BaseLevel node.
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

	var eye_pos := global_position + Vector3.UP * 1.5  ## Approximate eye height
	var to_player := _get_player_head_pos() - eye_pos
	var distance := to_player.length()

	# Range check (adjusted by weather/time visibility)
	if distance > _get_effective_sight_range():
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
		# "default", "idle": do nothing — stand still


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
	to_target.y = 0.0  ## Stay on same height plane
	var dist := to_target.length()

	if dist < 0.5:
		# Arrived at waypoint
		_patrol_waiting = true
		_patrol_wait_timer = patrol_wait_time
		return

	# Face target and walk toward it
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
	bullet.direction = aim_dir
	bullet.muzzle_velocity = enemy_bullet_speed
	bullet.is_enemy_bullet = true
	bullet.damage = shot_damage

	# Accuracy affects spread — lower accuracy = more spread
	var spread := deg_to_rad(inaccuracy_deg * (1.0 - accuracy))
	bullet.spread_angle = spread

	get_tree().root.add_child(bullet)
	bullet.global_position = eye_pos


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

	# Shock ammo — stun instead of damage
	if bullet.is_shock:
		stun(bullet.stun_duration)
		return

	var hit_point := collision.get_position()
	var is_headshot := _check_headshot(hit_point)
	var dmg := bullet.damage

	# Armor reduces damage unless AP or headshot
	if is_armored and not bullet.penetration and not is_headshot:
		dmg *= armor_reduction

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


## ── Stun ────────────────────────────────────────────────────────────────────

func stun(duration: float) -> void:
	## Freeze the enemy for the given duration. Called by shock ammo.
	if is_dead:
		return
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	_update_stun_visual(true)

	# Stunned enemy becomes alert after recovering
	if alert_state == AlertState.UNAWARE or alert_state == AlertState.SUSPICIOUS:
		suspicion = alert_threshold
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			last_known_player_pos = players[0].global_position


func _update_stun_visual(stunned: bool) -> void:
	## Tint mesh blue/electric when stunned, restore on recovery.
	if not mesh:
		return
	if stunned:
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
		# Remove override to restore original materials
		for child in mesh.get_children():
			if child is MeshInstance3D:
				child.material_override = null
			elif child is CSGShape3D:
				child.material = null


func _die(headshot: bool) -> void:
	is_dead = true
	enemy_killed.emit(self, headshot)

	# Hide debug visuals
	if _debug_mesh_instance:
		_debug_mesh_instance.visible = false
	if _state_indicator:
		_state_indicator.visible = false
	# Hide scope glint and laser
	_set_glint_visible(false)
	if _laser_mesh_instance:
		_laser_mesh_instance.visible = false

	# Report to RunManager with distance + headshot bonuses
	RunManager.record_shot_hit()
	RunManager.record_kill_with_bonus(self, headshot, credit_reward, xp_reward)

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


## ── Scope Glint ─────────────────────────────────────────────────────────

func _setup_glint() -> void:
	var glint_pos := Vector3(0, 1.5, -0.2)  ## Eye height, slightly forward

	# Billboard sprite — the visible glint star
	_glint_sprite = Sprite3D.new()
	_glint_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_glint_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint_sprite.position = glint_pos
	_glint_sprite.pixel_size = 0.005
	_glint_sprite.visible = false

	# Radial gradient texture (white center → transparent edge)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	_glint_sprite.texture = tex

	# Additive unshaded material
	_glint_material = StandardMaterial3D.new()
	_glint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glint_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glint_material.albedo_color = glint_color
	_glint_material.render_priority = 1
	_glint_sprite.material_override = _glint_material

	add_child(_glint_sprite)

	# OmniLight — subtle local glow on enemy body
	_glint_light = OmniLight3D.new()
	_glint_light.position = glint_pos
	_glint_light.omni_range = 2.0
	_glint_light.light_color = Color(glint_color.r, glint_color.g, glint_color.b)
	_glint_light.light_energy = 0.0
	_glint_light.visible = false

	add_child(_glint_light)


func _update_glint(delta: float) -> void:
	if not glint_enabled or not _glint_sprite:
		return

	var should_show := false

	if not is_dead:
		match alert_state:
			AlertState.ALERT:
				should_show = can_see_player
			AlertState.SUSPICIOUS:
				if glint_suspicious_flash and can_see_player:
					var ratio := suspicion / alert_threshold
					if ratio >= glint_suspicious_threshold:
						should_show = fmod(_glint_time * 4.0, 1.0) > 0.5

	_set_glint_visible(should_show)

	if should_show:
		_glint_time += delta
		var pulse := 0.5 + 0.5 * sin(_glint_time * glint_pulse_speed * TAU)
		_glint_material.albedo_color = glint_color * (0.5 + pulse * 0.5)
		_glint_light.light_energy = glint_max_energy * pulse
	else:
		_glint_time = 0.0


func _set_glint_visible(vis: bool) -> void:
	if _glint_active == vis:
		return
	_glint_active = vis
	if _glint_sprite:
		_glint_sprite.visible = vis
	if _glint_light:
		_glint_light.visible = vis


## ── Laser Sight ─────────────────────────────────────────────────────────

func _setup_laser() -> void:
	_laser_immediate_mesh = ImmediateMesh.new()
	_laser_mesh_instance = MeshInstance3D.new()
	_laser_mesh_instance.mesh = _laser_immediate_mesh
	_laser_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_laser_mesh_instance.visible = false

	_laser_material = StandardMaterial3D.new()
	_laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_laser_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_laser_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_laser_material.vertex_color_use_as_albedo = true
	_laser_material.no_depth_test = false

	add_child(_laser_mesh_instance)


func _update_laser() -> void:
	if not laser_enabled or not _laser_immediate_mesh:
		return

	var should_show := not is_dead
	_laser_mesh_instance.visible = should_show

	if not should_show:
		_laser_immediate_mesh.clear_surfaces()
		return

	# Build two crossing quads along the forward direction for visibility from any angle
	var eye := Vector3(0, 1.5, -0.2)
	var forward := -global_basis.z
	var end := eye + forward * laser_length
	var hw := laser_width * 0.5  ## Half width

	# Two perpendicular offsets for the cross shape
	var up := Vector3(0, hw, 0)
	var right := global_basis.x.normalized() * hw

	var color_start := laser_color
	var color_end := Color(laser_color.r, laser_color.g, laser_color.b, 0.0)

	_laser_immediate_mesh.clear_surfaces()
	_laser_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _laser_material)

	# Quad 1 — vertical cross section
	_draw_laser_quad(eye - up, eye + up, end + up, end - up, color_start, color_end)
	# Quad 2 — horizontal cross section
	_draw_laser_quad(eye - right, eye + right, end + right, end - right, color_start, color_end)

	_laser_immediate_mesh.surface_end()


func _draw_laser_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		color_start: Color, color_end: Color) -> void:
	# Triangle 1: a, b, c
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(a)
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(b)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(c)
	# Triangle 2: a, c, d
	_laser_immediate_mesh.surface_set_color(color_start)
	_laser_immediate_mesh.surface_add_vertex(a)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(c)
	_laser_immediate_mesh.surface_set_color(color_end)
	_laser_immediate_mesh.surface_add_vertex(d)


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
