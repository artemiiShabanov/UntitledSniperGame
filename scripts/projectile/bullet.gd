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
	elif tracer_color != Color.WHITE or tracer_emission > 1.0:
		# Player bullet with colored tracer (non-standard ammo)
		_apply_tracer_material(tracer_color, tracer_emission, Vector3(1.5, 1.5, 1.5))


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

	# Bullet drop
	velocity.y -= bullet_gravity * delta

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
		# Only player bullets alert enemies to impact sounds
		if not is_enemy_bullet:
			_propagate_impact_sound(collision.get_position())
		# Penetrating rounds pass through enemies (not world geometry)
		if penetration and hit_enemy:
			_already_hit.append(collider)
			damage *= 0.5  # Halve damage per penetration
		else:
			queue_free()


const IMPACT_LOUDNESS: float = 20.0

func _propagate_impact_sound(impact_pos: Vector3) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("hear_sound"):
			enemy.hear_sound(impact_pos, IMPACT_LOUDNESS)
	var npcs := get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.has_method("hear_sound"):
			npc.hear_sound(impact_pos, IMPACT_LOUDNESS)


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
