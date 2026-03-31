class_name DestructibleTarget
extends StaticBody3D
## A destructible object that can be shot for credits.
## Place in levels as static targets. Breaks on bullet hit.

signal target_destroyed(target: DestructibleTarget)

@export var health: float = 50.0
@export var credit_reward: int = 25
@export var xp_reward: int = 10

var is_destroyed: bool = false

@onready var mesh: Node3D = $Mesh


func _ready() -> void:
	PaletteManager.bind_meshes(self, PaletteManager.SLOT_ACCENT_LOOT)


func on_bullet_hit(bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_destroyed:
		return

	health -= bullet.damage
	if health <= 0.0:
		_destroy()


func _destroy() -> void:
	is_destroyed = true
	target_destroyed.emit(self)

	# Report reward
	RunManager.record_target_destroyed(credit_reward, xp_reward)

	# Visual — darken to fg_dark
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = PaletteManager.get_color(PaletteManager.SLOT_FG_DARK)
		for child in mesh.get_children():
			if child is MeshInstance3D:
				child.material_override = mat
			elif child is CSGShape3D:
				child.material = mat

	# Disable collision
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Remove after delay
	var tree := get_tree()
	if tree:
		var timer := tree.create_timer(5.0)
		timer.timeout.connect(func(): if is_instance_valid(self): queue_free())
