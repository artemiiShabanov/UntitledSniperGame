class_name DestructibleCrate
extends DestructibleTarget
## Static crate — part of level blocks. Low reward filler target.
## Skins: wooden crate, cardboard box, trash can.

enum SkinType { WOODEN_CRATE, CARDBOARD_BOX, TRASH_CAN }

@export var skin: SkinType = SkinType.WOODEN_CRATE


func _ready() -> void:
	credit_reward = 15
	xp_reward = 5
	_apply_skin()
	super._ready()


func _apply_skin() -> void:
	if not mesh:
		return
	var body: MeshInstance3D = mesh.get_node_or_null("Body")
	if not body:
		return

	match skin:
		SkinType.WOODEN_CRATE:
			body.mesh = _make_box_mesh(Vector3(1.0, 1.0, 1.0))
		SkinType.CARDBOARD_BOX:
			body.mesh = _make_box_mesh(Vector3(0.8, 0.6, 0.8))
		SkinType.TRASH_CAN:
			body.mesh = _make_cylinder_mesh(0.35, 0.9)


func _make_box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _make_cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m
