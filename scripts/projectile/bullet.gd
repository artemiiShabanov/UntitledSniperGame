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
		if collider.has_method("on_bullet_hit"):
			collider.on_bullet_hit(self, collision)
		queue_free()
