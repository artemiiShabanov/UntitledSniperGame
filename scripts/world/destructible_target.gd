class_name DestructibleTarget
extends StaticBody3D
## Base class for static destructible objects.
## One-shot kill — any bullet hit destroys it instantly.

signal target_destroyed(target: DestructibleTarget)

@export var credit_reward: int = 25
@export var xp_reward: int = 10
@export var fade_delay: float = 5.0  ## Seconds before removal after destruction

var is_destroyed: bool = false

@onready var mesh: Node3D = $Mesh


func _ready() -> void:
	add_to_group("destructible")
	PaletteManager.bind_meshes(self, PaletteManager.SLOT_ACCENT_LOOT)


func on_bullet_hit(_bullet: Bullet, _collision: KinematicCollision3D) -> void:
	if is_destroyed:
		return
	_destroy()


func _destroy() -> void:
	is_destroyed = true
	target_destroyed.emit(self)

	RunManager.record_target_destroyed(credit_reward, xp_reward)
	AudioManager.play_sfx(&"target_destroyed", global_position)

	_on_destroy()

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if fade_delay > 0.0:
		var tree := get_tree()
		if tree:
			var timer := tree.create_timer(fade_delay)
			timer.timeout.connect(func(): if is_instance_valid(self): queue_free())
	else:
		queue_free()


## Override in subclasses for custom destruction visuals
func _on_destroy() -> void:
	_darken_mesh()


func _darken_mesh() -> void:
	if not mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PaletteManager.get_color(PaletteManager.SLOT_FG_DARK)
	for child in mesh.get_children():
		if child is MeshInstance3D:
			child.material_override = mat
		elif child is CSGShape3D:
			child.material = mat
