class_name DestructibleBottle
extends DestructibleTarget
## Static bottle — tiny target on railings, windowsills, tables.
## Skins: bottle, jar, mug.

enum SkinType { BOTTLE, JAR, MUG }

@export var skin: SkinType = SkinType.BOTTLE


func _ready() -> void:
	credit_reward = 20
	xp_reward = 8
	_apply_skin()
	super._ready()


func _apply_skin() -> void:
	if not mesh:
		return
	var body: MeshInstance3D = mesh.get_node_or_null("Body")
	if not body:
		return

	match skin:
		SkinType.BOTTLE:
			body.mesh = _make_cylinder_mesh(0.06, 0.3)
		SkinType.JAR:
			body.mesh = _make_cylinder_mesh(0.08, 0.15)
		SkinType.MUG:
			body.mesh = _make_cylinder_mesh(0.06, 0.12)


func _make_cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m


func _on_destroy() -> void:
	# Bottles just disappear instantly — shatter
	AudioManager.play_sfx(&"glass_break", global_position)
	if mesh:
		mesh.visible = false
