class_name WarriorRangedBase
extends WarriorBase
## Base for ranged warriors. Advances to firing range, then stops and shoots at the player.
## Ranged warriors don't melee — they are never paired by CombatManager.

enum RangedState { ADVANCING_TO_RANGE, FIRING, REPOSITIONING }

const RANGED_STATE_COLORS := {
	RangedState.ADVANCING_TO_RANGE: Color(0.2, 0.6, 1.0),  # Blue — moving
	RangedState.FIRING: Color(1.0, 0.5, 0.0),               # Orange — shooting
	RangedState.REPOSITIONING: Color(0.8, 0.8, 0.2),        # Yellow — relocating
}

@export var firing_range: float = 90.0      ## Stop advancing at this distance from player
@export var accuracy: float = 0.3           ## Hit chance per shot (0-1)
@export var shoot_interval: float = 2.5     ## Seconds between shots
@export var projectile_speed: float = 40.0  ## Arrow/bolt travel speed
@export var reposition_chance: float = 0.0  ## Chance to reposition after each shot
@export var reposition_radius: float = 10.0

var ranged_state: RangedState = RangedState.ADVANCING_TO_RANGE
var _shoot_timer: float = 0.0
var _reposition_target: Vector3 = Vector3.ZERO

@export var arrow_scene: PackedScene  ## Projectile scene for this ranged type


func _ready() -> void:
	super._ready()
	_shoot_timer = shoot_interval * randf_range(0.5, 1.0)  # Stagger first shot


func is_pairable() -> bool:
	## Ranged warriors don't melee pair.
	return false


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_set_debug_sphere_color(RANGED_STATE_COLORS.get(ranged_state, Color.WHITE))

	match ranged_state:
		RangedState.ADVANCING_TO_RANGE:
			_process_advance_to_range(delta)
		RangedState.FIRING:
			_process_firing(delta)
		RangedState.REPOSITIONING:
			_process_repositioning(delta)


func _process_advance_to_range(delta: float) -> void:
	var player := _get_player()
	if not player:
		_move_along_nav(delta)
		return

	var dist := global_position.distance_to(player.global_position)
	if dist <= firing_range:
		ranged_state = RangedState.FIRING
		_shoot_timer = shoot_interval * randf_range(0.3, 0.7)
		return

	# Keep advancing toward player's general direction.
	_set_nav_target(player.global_position)
	_move_along_nav(delta)


func _process_firing(delta: float) -> void:
	var player := _get_player()
	if not player:
		return

	# Face the player.
	var dir := (player.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		look_at(global_position + dir.normalized(), Vector3.UP)

	# If player has moved out of range, re-advance.
	var dist := global_position.distance_to(player.global_position)
	if dist > firing_range * 1.3:
		ranged_state = RangedState.ADVANCING_TO_RANGE
		_set_nav_target(player.global_position)
		return

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval
		_shoot_at_player(player)

		# Maybe reposition after shooting.
		if reposition_chance > 0.0 and randf() < reposition_chance:
			_start_reposition()


func _process_repositioning(delta: float) -> void:
	_move_along_nav(delta)
	var dist := global_position.distance_to(_move_target)
	if dist < 2.0:
		ranged_state = RangedState.FIRING
		_shoot_timer = shoot_interval * randf_range(0.3, 0.7)


func _start_reposition() -> void:
	var offset := Vector3(
		randf_range(-reposition_radius, reposition_radius),
		0.0,
		randf_range(-reposition_radius, reposition_radius),
	)
	_set_nav_target(global_position + offset)
	ranged_state = RangedState.REPOSITIONING


func _shoot_at_player(player: Node3D) -> void:
	## Spawns a projectile aimed at the player. Accuracy determines hit/miss.
	if not arrow_scene:
		# Fallback: direct hit check without projectile.
		if randf() < accuracy:
			RunManager.take_hit()
		return

	var projectile: Node3D = arrow_scene.instantiate()
	var spawn_pos := global_position + Vector3.UP * 1.5
	var target_pos := player.global_position + Vector3.UP * 1.0

	# Apply inaccuracy — offset target position.
	if randf() > accuracy:
		var miss_offset := Vector3(
			randf_range(-3.0, 3.0),
			randf_range(-1.5, 1.5),
			randf_range(-3.0, 3.0),
		)
		target_pos += miss_offset

	var dir := (target_pos - spawn_pos).normalized()

	if projectile.has_method("setup"):
		projectile.setup(dir, projectile_speed)
	else:
		projectile.direction = dir
		projectile.muzzle_velocity = projectile_speed

	projectile.is_enemy_bullet = true
	# Spawn ahead of the archer so it doesn't hit the shooter.
	var forward_offset := dir * 1.5
	var level := get_tree().current_scene
	if level:
		level.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	projectile.global_position = spawn_pos + forward_offset
	# Also add collision exception for the shooter.
	projectile.add_collision_exception_with(self)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
