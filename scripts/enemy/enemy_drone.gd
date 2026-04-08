class_name EnemyDrone
extends EnemyBase
## Drone — flying patrol unit that hovers at a fixed height and scans below.
## Uses the standard alert state machine. Shares detection, combat, and
## sound reaction with other enemies. Distinct because it flies and has
## a wide downward-angled FOV covering the ground beneath.
##
## Movement:
## - UNAWARE / SEARCHING: circles around its origin point
## - SUSPICIOUS / ALERT: flies toward player position

@export var fly_height: float = 12.0  ## Hover height above ground
@export var fly_speed: float = 3.0
@export var buzz_range: float = 60.0
@export var circle_radius: float = 15.0  ## Radius of patrol circle
@export var circle_speed: float = 0.5  ## Radians per second

var _buzz_timer: float = 0.0
var _fly_target_y: float = 0.0
var _circle_center: Vector3 = Vector3.ZERO
var _circle_angle: float = 0.0

const BUZZ_INTERVAL: float = 0.8


func _ready() -> void:
	fov_degrees = 120.0  ## Wide cone — covers large ground area from above
	max_sight_range = 50.0  ## Short range (close to targets vertically)
	suspicion_rate = 0.5
	suspicion_decay = 0.2
	alert_threshold = 0.8
	search_duration = 6.0

	reaction_time = 1.5
	fire_interval = 3.0
	accuracy = 0.3
	inaccuracy_deg = 8.0  ## Poor accuracy — suppressive fire from above
	health = 30.0  ## Fragile — one good shot
	shot_damage = 1.0

	initial_behavior = Behavior.DEFAULT  ## Custom movement, not base patrol/scan
	patrol_speed = fly_speed

	credit_reward = 40
	xp_reward = 20

	body_color = Color(0.7, 0.6, 0.1)  # Warning yellow

	glint_enabled = false
	laser_enabled = false

	super._ready()

	_fly_target_y = maxf(global_position.y, fly_height)
	_circle_center = Vector3(global_position.x, 0, global_position.z)
	_circle_angle = randf() * TAU


func _physics_process(delta: float) -> void:
	if is_dead or is_stunned or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	_maintain_altitude(delta)
	_update_buzz(delta)
	super._physics_process(delta)


func _maintain_altitude(delta: float) -> void:
	if absf(global_position.y - _fly_target_y) > 0.1:
		global_position.y = move_toward(global_position.y, _fly_target_y, fly_speed * delta)


## Override behavior to use custom drone movement
func _update_behavior(delta: float) -> void:
	match alert_state:
		AlertState.SUSPICIOUS, AlertState.ALERT:
			_fly_toward_player(delta)
		AlertState.UNAWARE, AlertState.SEARCHING:
			_fly_circle(delta)


## Override combat — fly toward player AND shoot
func _update_combat(delta: float) -> void:
	if alert_state != AlertState.ALERT:
		return

	# Don't call _face_player_smooth — drone faces movement direction in _fly_toward_player

	if reaction_timer > 0.0:
		reaction_timer -= delta
		return

	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire_at_player()
		fire_timer = fire_interval


func _fly_toward_player(delta: float) -> void:
	if not player:
		return
	var target_pos := player.global_position if can_see_player else last_known_player_pos
	var to_target := Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z)
	var dist := to_target.length()

	if dist > 2.0:
		var dir := to_target.normalized()
		_face_direction_smooth(dir, delta)
		var facing := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		velocity = facing * fly_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	# Update circle center to current position so circling resumes here
	_circle_center = Vector3(global_position.x, 0, global_position.z)


func _fly_circle(delta: float) -> void:
	_circle_angle += circle_speed * delta

	var target_x := _circle_center.x + cos(_circle_angle) * circle_radius
	var target_z := _circle_center.z + sin(_circle_angle) * circle_radius
	var to_target := Vector3(target_x - global_position.x, 0, target_z - global_position.z)

	if to_target.length_squared() > 0.1:
		var dir := to_target.normalized()
		_face_direction_smooth(dir, delta)
		var facing := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		velocity = facing * fly_speed
		move_and_slide()


## Override LOS to look from drone center instead of EYE_HEIGHT
func _update_line_of_sight() -> void:
	can_see_player = false

	if not player:
		return

	var eye_pos := global_position
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


## Override fire to shoot from drone center, not EYE_HEIGHT
func _fire_at_player() -> void:
	if not can_see_player or not player:
		return

	var eye_pos := global_position
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

	VFXFactory.spawn_muzzle_flash(eye_pos, aim_dir, true)
	AudioManager.play_sfx(&"rifle_fire", eye_pos)


func _update_buzz(delta: float) -> void:
	if not player:
		return
	_buzz_timer -= delta
	if _buzz_timer <= 0.0:
		_buzz_timer = BUZZ_INTERVAL
		var dist := global_position.distance_to(player.global_position)
		if dist <= buzz_range:
			AudioManager.play_sfx(&"drone_buzz", global_position)


## Drones have no head — headshots not possible
func _check_headshot(_hit_point: Vector3) -> bool:
	return false
