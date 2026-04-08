class_name BlockBuilderBase
extends RefCounted
## Base class for code-based block geometry builders.
## Blocks generate greybox geometry at runtime (same pattern as IndustrialYardBuilder).
## Each subclass builds a specific block type and adds spawn/activity markers.

var root: Node3D
var rng: RandomNumberGenerator


func setup(block_root: Node3D, p_rng: RandomNumberGenerator) -> void:
	root = block_root
	rng = p_rng


## Override in subclasses to build geometry and markers.
func build() -> void:
	pass


## ── Materials ────────────────────────────────────────────────────────────────
## Shared material cache — created once per builder instance.

var _mat_cache: Dictionary = {}

func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if key in _mat_cache:
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	_mat_cache[key] = mat
	return mat

## Common industrial palette
func mat_concrete() -> StandardMaterial3D: return _mat(Color(0.55, 0.53, 0.50))
func mat_metal() -> StandardMaterial3D: return _mat(Color(0.45, 0.47, 0.50))
func mat_dark_metal() -> StandardMaterial3D: return _mat(Color(0.25, 0.25, 0.28))
func mat_rust() -> StandardMaterial3D: return _mat(Color(0.55, 0.35, 0.20))
func mat_yellow() -> StandardMaterial3D: return _mat(Color(0.75, 0.65, 0.15))


## ── Geometry helpers ─────────────────────────────────────────────────────────

func add_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D, node_name: String = "Box") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	root.add_child(body)
	return body


func add_cylinder(pos: Vector3, radius: float, height: float, mat: StandardMaterial3D, node_name: String = "Cyl") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = radius
	cyl_mesh.bottom_radius = radius
	cyl_mesh.height = height
	cyl_mesh.material = mat
	mesh_inst.mesh = cyl_mesh
	body.add_child(mesh_inst)

	root.add_child(body)
	return body


func add_ramp(pos: Vector3, size: Vector3, angle_deg: float, mat: StandardMaterial3D, node_name: String = "Ramp") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.rotation_degrees.x = -angle_deg

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	root.add_child(body)
	return body


## ── Marker helpers ───────────────────────────────────────────────────────────

func add_enemy_spawn(pos: Vector3, facing_deg: float = 0.0, group: String = "", behavior: String = "default") -> SpawnPoint:
	var sp := SpawnPoint.new()
	sp.name = "EnemySpawn_%d" % root.get_child_count()
	sp.spawn_type = SpawnPoint.Type.ENEMY
	sp.position = pos
	sp.facing_direction = facing_deg
	sp.spawn_group = group
	sp.behavior_tag = behavior
	root.add_child(sp)
	return sp


func add_destructible_spawn(pos: Vector3, group: String = "") -> SpawnPoint:
	var sp := SpawnPoint.new()
	sp.name = "DestructibleSpawn_%d" % root.get_child_count()
	sp.spawn_type = SpawnPoint.Type.DESTRUCTIBLE
	sp.position = pos
	sp.spawn_group = group
	root.add_child(sp)
	return sp


func add_activity_point(pos: Vector3, activity: ActivityPoint.Activity, facing_deg: float = 0.0, group: String = "") -> ActivityPoint:
	var ap := ActivityPoint.new()
	ap.name = "ActivityPoint_%d" % root.get_child_count()
	ap.activity = activity
	ap.position = pos
	ap.facing_direction = facing_deg
	ap.point_group = group
	root.add_child(ap)
	return ap


## ── Randomization helpers ────────────────────────────────────────────────────

func rand_offset(max_offset: float) -> float:
	return rng.randf_range(-max_offset, max_offset)


func rand_range(min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)


func maybe(chance: float = 0.5) -> bool:
	return rng.randf() < chance
