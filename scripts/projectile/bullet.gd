class_name Bullet
extends CharacterBody3D
## Projectile-based bullet with gravity (bullet drop) and travel time.

@export var muzzle_velocity: float = 300.0
@export var bullet_gravity: float = 9.8
@export var lifetime: float = 5.0
@export var damage: float = 100.0
@export var penetration: bool = false

var direction: Vector3 = Vector3.FORWARD
var spread_angle: float = 0.0  ## Radians, applied on spawn
var time_alive: float = 0.0
var is_enemy_bullet: bool = false  ## Set by enemy to change collision mask + color
var _already_hit: Array[Node] = []  ## Track penetrated targets to avoid double-hit

## Ammo type properties (set by weapon before adding to scene)
var ammo_type: AmmoType = null
var is_shock: bool = false
var stun_duration: float = 4.0
var tracer_color: Color = Color.WHITE
var tracer_emission: float = 1.0


func _ready() -> void:
	# Apply spread offset to direction
	if spread_angle > 0.0:
		var random_axis := direction.cross(Vector3.UP).normalized()
		if random_axis.length_squared() < 0.001:
			random_axis = direction.cross(Vector3.RIGHT).normalized()
		direction = direction.rotated(random_axis, randf_range(-spread_angle, spread_angle))
		direction = direction.rotated(direction.cross(random_axis).normalized(), randf_range(-spread_angle, spread_angle))
		direction = direction.normalized()

	velocity = direction * muzzle_velocity

	if is_enemy_bullet:
		# Enemy bullets hit Environment (1) + Player (2) = mask 3
		collision_mask = 3
		_apply_tracer_material(Color(1.0, 0.4, 0.1), 3.0, Vector3(3.0, 3.0, 3.0))
		VFXFactory.add_tracer_trail(self, Color(1.0, 0.4, 0.1), 1.5)
	elif tracer_color != Color.WHITE or tracer_emission > 1.0:
		# Player bullet with colored tracer (non-standard ammo)
		_apply_tracer_material(tracer_color, tracer_emission, Vector3(1.5, 1.5, 1.5))
		VFXFactory.add_tracer_trail(self, tracer_color, 2.0)
	else:
		# Standard player bullet — subtle white trail
		VFXFactory.add_tracer_trail(self, Color(0.8, 0.8, 0.8, 0.4), 1.5)


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

	# Bullet drop
	velocity.y -= bullet_gravity * delta

	# Enemy bullet whizz near player
	if is_enemy_bullet:
		_check_whizz()

	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		var hit_enemy := false
		if collider and collider not in _already_hit:
			if collider.has_method("on_bullet_hit"):
				collider.on_bullet_hit(self, collision)
				hit_enemy = collider.is_in_group("enemy")
			elif is_shock and collider.has_method("stun"):
				collider.stun(stun_duration)
				hit_enemy = collider.is_in_group("enemy")
		# Spawn impact VFX + audio
		var hit_normal := collision.get_normal()
		var hit_pos := collision.get_position()
		VFXFactory.spawn_hit_impact(hit_pos, hit_normal, false)

		# Impact sound based on what was hit
		if collider and collider.is_in_group("enemy"):
			if collider.has_method("_check_headshot") and collider._check_headshot(hit_pos):
				AudioManager.play_sfx(&"impact_head", hit_pos)
			else:
				AudioManager.play_sfx(&"impact_body", hit_pos)
		elif collider and collider is DestructibleTarget:
			AudioManager.play_sfx(&"impact_destructible", hit_pos)
		else:
			AudioManager.play_sfx(&"impact_world", hit_pos)

		# Only player bullets alert enemies to impact sounds
		if not is_enemy_bullet:
			_propagate_impact_sound(hit_pos)
		# Penetrating rounds pass through enemies (not world geometry)
		if penetration and hit_enemy:
			_already_hit.append(collider)
			damage *= 0.5  # Halve damage per penetration
			AudioManager.play_sfx(&"bullet_penetrate", hit_pos)
		else:
			queue_free()


## ── Bullet whizz ──────────────────────────────────────────────────────────

const WHIZZ_DISTANCE: float = 5.0  ## Max distance to player for whizz sound
var _whizz_played: bool = false

func _check_whizz() -> void:
	if _whizz_played:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_pos: Vector3 = players[0].global_position
	if global_position.distance_squared_to(player_pos) < WHIZZ_DISTANCE * WHIZZ_DISTANCE:
		AudioManager.play_sfx(&"bullet_whizz", global_position)
		_whizz_played = true


var impact_loudness: float = 20.0

func _propagate_impact_sound(impact_pos: Vector3) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("hear_sound"):
			enemy.hear_sound(impact_pos, impact_loudness)
	var npcs := get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.has_method("hear_sound"):
			npc.hear_sound(impact_pos, impact_loudness)


func _apply_tracer_material(color: Color, emission: float, mesh_scale: Vector3) -> void:
	var mesh_node := get_node_or_null("MeshInstance3D")
	if mesh_node:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_node.material_override = mat
		mesh_node.scale = mesh_scale
