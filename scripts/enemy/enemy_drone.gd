class_name EnemyDrone
extends CharacterBody3D
## Drone — flying unit that moves toward the player's position.
## Ignores terrain/elevation. Low HP (one shot). Deals 1 life of damage
## on proximity, then self-destructs. Audible buzz as warning.
##
## Does NOT extend EnemyBase — drones have no LOS, alert states, or combat.
## Compatible with the enemy group and kill tracking systems.

signal enemy_killed(enemy: EnemyDrone, headshot: bool)

@export var fly_speed: float = 8.0
@export var health: float = 30.0
@export var proximity_damage_range: float = 3.0
@export var credit_reward: int = 40
@export var xp_reward: int = 20
@export var buzz_range: float = 60.0  ## Range at which buzz is audible
@export var turn_speed: float = 5.0

var is_dead: bool = false
var player: Node3D = null
var _buzz_timer: float = 0.0

const BUZZ_INTERVAL: float = 0.8


func _ready() -> void:
	add_to_group("enemy")
	_find_player()

	var mesh_node := get_node_or_null("Mesh")
	if mesh_node:
		for child in mesh_node.get_children():
			if child is MeshInstance3D:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.7, 0.6, 0.1) if child.name == "Body" else Color(0.15, 0.15, 0.15)
				child.material_override = mat


func _physics_process(delta: float) -> void:
	if is_dead or RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	if not player:
		_find_player()
		if not player:
			return

	_move_toward_target(delta)
	_check_proximity()
	_update_buzz(delta)


func _move_toward_target(delta: float) -> void:
	var to_target := player.global_position - global_position
	var dist := to_target.length()

	if dist < 0.5:
		return

	var dir := to_target.normalized()
	velocity = dir * fly_speed

	# Smooth facing toward movement direction
	var flat_dir := Vector3(dir.x, 0, dir.z)
	if flat_dir.length_squared() > 0.001:
		var target_yaw := atan2(-flat_dir.x, -flat_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	move_and_slide()


func _check_proximity() -> void:
	if not player:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= proximity_damage_range:
		RunManager.take_hit()
		AudioManager.play_sfx(&"bullet_impact_body", global_position)
		_die(false)


func _update_buzz(delta: float) -> void:
	if not player:
		return
	_buzz_timer -= delta
	if _buzz_timer <= 0.0:
		_buzz_timer = BUZZ_INTERVAL
		var dist := global_position.distance_to(player.global_position)
		if dist <= buzz_range:
			AudioManager.play_sfx(&"drone_buzz", global_position)


## ── Damage ──────────────────────────────────────────────────────────────────

func on_bullet_hit(bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_dead:
		return

	health -= bullet.damage
	if health <= 0.0:
		_die(false)


func _die(headshot: bool) -> void:
	is_dead = true
	enemy_killed.emit(self, headshot)

	RunManager.record_shot_hit()
	RunManager.record_kill_with_bonus(self, headshot, credit_reward, xp_reward)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	VFXFactory.spawn_death_effect(self, false)


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
