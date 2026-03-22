class_name IndustrialYardBuilder
extends RefCounted
## Procedurally builds the Industrial Yard level geometry at runtime.
## Attach to the level scene — creates buildings, cover, and structures.
## This keeps the .tscn clean and makes iteration easy.

## ── Materials ───────────────────────────────────────────────────────────────

var mat_ground: StandardMaterial3D
var mat_concrete: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_dark_metal: StandardMaterial3D
var mat_rust: StandardMaterial3D
var mat_yellow: StandardMaterial3D

var parent: Node3D


func build(level_root: Node3D) -> void:
	parent = level_root
	_create_materials()
	_build_ground()
	_build_player_tower()
	_build_warehouses()
	_build_silos()
	_build_crane()
	_build_containers()
	_build_walls_and_fences()
	_build_misc_cover()


func _create_materials() -> void:
	mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.25, 0.27, 0.22)  ## Dark olive ground

	mat_concrete = StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.55, 0.53, 0.50)  ## Grey concrete

	mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.45, 0.47, 0.50)  ## Blue-grey metal

	mat_dark_metal = StandardMaterial3D.new()
	mat_dark_metal.albedo_color = Color(0.25, 0.25, 0.28)  ## Dark steel

	mat_rust = StandardMaterial3D.new()
	mat_rust.albedo_color = Color(0.55, 0.35, 0.20)  ## Rusty orange

	mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.75, 0.65, 0.15)  ## Safety yellow


## ── Ground ─────────────────────────────────────────────────────────────────

func _build_ground() -> void:
	# Main ground plane 300x300
	_add_box(Vector3(0, -0.5, 0), Vector3(300, 1, 300), mat_ground, "Ground")

	# Concrete pads under main structures
	_add_box(Vector3(0, 0.02, -100), Vector3(80, 0.1, 60), mat_concrete, "Pad_Warehouse")
	_add_box(Vector3(-80, 0.02, -60), Vector3(40, 0.1, 40), mat_concrete, "Pad_Silos")
	_add_box(Vector3(80, 0.02, -40), Vector3(50, 0.1, 50), mat_concrete, "Pad_Loading")


## ── Player Tower (spawn point — elevated sniper nest) ─────────────────────

func _build_player_tower() -> void:
	# Player starts on a tall observation tower at the south edge
	# Position: (0, 0, 80) — looking north into the yard
	# Height: ~18m — great vantage point over the 300m yard

	# Tower base (concrete pillar)
	_add_box(Vector3(0, 7.5, 80), Vector3(4, 15, 4), mat_concrete, "PlayerTower_Base")

	# Tower platform (wide top)
	_add_box(Vector3(0, 15.25, 80), Vector3(8, 0.5, 8), mat_metal, "PlayerTower_Platform")

	# Railing walls (low cover on platform)
	_add_box(Vector3(0, 16, 76.2), Vector3(8, 1.2, 0.3), mat_metal, "PlayerTower_RailN")
	_add_box(Vector3(0, 16, 83.8), Vector3(8, 1.2, 0.3), mat_metal, "PlayerTower_RailS")
	_add_box(Vector3(-3.85, 16, 80), Vector3(0.3, 1.2, 8), mat_metal, "PlayerTower_RailW")
	_add_box(Vector3(3.85, 16, 80), Vector3(0.3, 1.2, 8), mat_metal, "PlayerTower_RailE")

	# Access ramp from ground (so player can descend to extract)
	# Ramp goes from ground level to platform, angled
	_add_ramp(Vector3(6, 7.5, 80), Vector3(4, 0.3, 20), 37.0, mat_dark_metal, "PlayerTower_Ramp")

	# Secondary vantage — small platform to the west connected by zipline
	_add_box(Vector3(-60, 9.5, 60), Vector3(5, 0.5, 5), mat_metal, "WestPlatform")
	_add_box(Vector3(-60, 7, 60), Vector3(3, 14, 3), mat_concrete, "WestPlatform_Base")
	# Railings
	_add_box(Vector3(-60, 10.3, 57.7), Vector3(5, 1, 0.3), mat_metal, "WestPlat_RailN")

	# Third vantage — east crane cab (see _build_crane)


## ── Warehouses (main target buildings, 100-150m from player) ──────────────

func _build_warehouses() -> void:
	# Warehouse A — large, 120m north of player tower
	# Center at (0, 0, -40), dimensions 40x10x25
	_add_box(Vector3(0, 5, -40), Vector3(40, 10, 25), mat_metal, "WarehouseA")
	# Roof (slightly wider)
	_add_box(Vector3(0, 10.15, -40), Vector3(42, 0.3, 27), mat_dark_metal, "WarehouseA_Roof")
	# Open bay doors (gaps — enemies visible through them)
	# South face openings — just don't build full walls, leave gaps
	# Loading dock platform
	_add_box(Vector3(0, 0.6, -27), Vector3(30, 1.2, 4), mat_concrete, "WarehouseA_Dock")

	# Warehouse B — east side, angled, 130m from player
	_add_box(Vector3(60, 4, -50), Vector3(25, 8, 20), mat_metal, "WarehouseB")
	_add_box(Vector3(60, 8.15, -50), Vector3(27, 0.3, 22), mat_dark_metal, "WarehouseB_Roof")
	# Roof access ladder platform
	_add_box(Vector3(72, 8.5, -50), Vector3(4, 0.3, 6), mat_metal, "WarehouseB_RoofAccess")

	# Warehouse C — west side, 140m from player
	_add_box(Vector3(-55, 5, -70), Vector3(30, 10, 20), mat_rust, "WarehouseC")
	_add_box(Vector3(-55, 10.15, -70), Vector3(32, 0.3, 22), mat_dark_metal, "WarehouseC_Roof")

	# Small office building between warehouses — interior provides cover
	_add_box(Vector3(25, 3, -20), Vector3(10, 6, 8), mat_concrete, "Office")
	_add_box(Vector3(25, 6.15, -20), Vector3(11, 0.3, 9), mat_dark_metal, "Office_Roof")


## ── Silos (tall structures for enemy snipers, 150m from player) ───────────

func _build_silos() -> void:
	# Cluster of 3 silos — west side, far from player
	for i in range(3):
		var x := -80.0 + i * 12.0
		var z := -60.0
		var height := 12.0 + i * 2.0
		_add_cylinder(Vector3(x, height * 0.5, z), 4.0, height, mat_metal, "Silo_%d" % i)
		# Catwalk around top
		_add_box(Vector3(x, height + 0.15, z), Vector3(10, 0.3, 10), mat_dark_metal, "Silo_%d_Catwalk" % i)

	# Connecting catwalk between silos
	_add_box(Vector3(-80, 12.15, -60), Vector3(30, 0.3, 2), mat_dark_metal, "Silo_Bridge")


## ── Crane (east side, alternative vantage point) ──────────────────────────

func _build_crane() -> void:
	# Tall crane on east side — enemy snipers on the arm, player can zipline here
	var cx := 80.0
	var cz := 20.0

	# Crane tower (vertical)
	_add_box(Vector3(cx, 12, cz), Vector3(3, 24, 3), mat_yellow, "Crane_Tower")

	# Crane arm (horizontal, extends north over the yard)
	_add_box(Vector3(cx, 24.25, cz - 20), Vector3(3, 0.5, 40), mat_yellow, "Crane_Arm")

	# Crane cab platform
	_add_box(Vector3(cx, 12.25, cz), Vector3(5, 0.5, 5), mat_dark_metal, "Crane_Cab")

	# Counter-weight
	_add_box(Vector3(cx, 23, cz + 18), Vector3(4, 3, 4), mat_dark_metal, "Crane_Weight")


## ── Shipping Containers (scattered cover, 80-120m from player) ────────────

func _build_containers() -> void:
	# Standard shipping container: ~12x2.5x2.5m
	var container_positions := [
		# Near warehouse A loading dock — cluster
		Vector3(-15, 1.25, -22), Vector3(-15, 3.75, -22),  ## Stacked
		Vector3(-8, 1.25, -20),
		Vector3(12, 1.25, -24),
		Vector3(15, 1.25, -18),
		# Scattered across yard
		Vector3(30, 1.25, -10),
		Vector3(-30, 1.25, -30),
		Vector3(45, 1.25, -35),
		Vector3(-40, 1.25, -40),
		# Near extraction zones
		Vector3(-90, 1.25, -100),
		Vector3(100, 1.25, 30),
	]

	var container_rotations := [
		0.0, 0.0, 25.0, -10.0, 45.0,
		0.0, 15.0, -30.0, 60.0,
		10.0, -20.0,
	]

	for i in container_positions.size():
		var rot: float = container_rotations[i] if i < container_rotations.size() else 0.0
		var mat: StandardMaterial3D = mat_rust if i % 3 == 0 else (mat_metal if i % 3 == 1 else mat_dark_metal)
		_add_rotated_box(container_positions[i], Vector3(12, 2.5, 2.5), rot, mat, "Container_%d" % i)


## ── Perimeter Walls and Fences ────────────────────────────────────────────

func _build_walls_and_fences() -> void:
	# Compound perimeter — concrete walls on north side, chain-link elsewhere
	# North wall (far end, 230m from player)
	_add_box(Vector3(0, 2, -148), Vector3(300, 4, 0.5), mat_concrete, "Wall_North")
	# East wall
	_add_box(Vector3(148, 1.5, -30), Vector3(0.5, 3, 260), mat_concrete, "Wall_East")
	# West wall
	_add_box(Vector3(-148, 1.5, -30), Vector3(0.5, 3, 260), mat_concrete, "Wall_West")

	# Internal dividing walls — create wind corridors
	# Low wall splitting the yard east-west (forces engagement through gaps)
	_add_box(Vector3(-40, 1.5, -10), Vector3(40, 3, 0.5), mat_concrete, "DivWall_W")
	_add_box(Vector3(40, 1.5, -10), Vector3(40, 3, 0.5), mat_concrete, "DivWall_E")
	# Gap in the middle (20m wide) — wind corridor!

	# Low barriers near loading dock
	_add_box(Vector3(-20, 0.5, -15), Vector3(8, 1, 0.4), mat_concrete, "Barrier_1")
	_add_box(Vector3(20, 0.5, -15), Vector3(8, 1, 0.4), mat_concrete, "Barrier_2")


## ── Miscellaneous Cover ───────────────────────────────────────────────────

func _build_misc_cover() -> void:
	# Fuel tanks
	_add_cylinder(Vector3(40, 2, 10), 2.5, 4, mat_dark_metal, "FuelTank_1")
	_add_cylinder(Vector3(45, 2, 12), 2.5, 4, mat_dark_metal, "FuelTank_2")

	# Concrete barriers scattered through yard
	var barrier_positions := [
		Vector3(10, 0.5, 0),
		Vector3(-10, 0.5, 10),
		Vector3(25, 0.5, 20),
		Vector3(-25, 0.5, -5),
		Vector3(50, 0.5, 0),
		Vector3(-50, 0.5, 10),
	]
	for i in barrier_positions.size():
		_add_box(barrier_positions[i], Vector3(3, 1, 0.5), mat_concrete, "JerseyBarrier_%d" % i)

	# Pallets/crates near warehouses
	for i in range(6):
		var x := randf_range(-15, 15)
		var z := randf_range(-35, -25)
		_add_box(Vector3(x, 0.5, z), Vector3(1.5, 1, 1.5), mat_rust, "Crate_%d" % i)

	# Scaffolding (partial sight blocker near warehouse C)
	_add_box(Vector3(-55, 6, -58), Vector3(10, 0.2, 3), mat_dark_metal, "Scaffold_Floor1")
	_add_box(Vector3(-55, 9, -58), Vector3(10, 0.2, 3), mat_dark_metal, "Scaffold_Floor2")
	# Scaffold poles
	for x_off in [-4.5, 4.5]:
		for z_off in [-1.0, 1.0]:
			_add_box(Vector3(-55 + x_off, 4.5, -58 + z_off), Vector3(0.15, 9, 0.15), mat_dark_metal, "Scaffold_Pole")


## ── Geometry Helpers ───────────────────────────────────────────────────────

func _add_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D, node_name: String) -> StaticBody3D:
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

	parent.add_child(body)
	return body


func _add_rotated_box(pos: Vector3, size: Vector3, y_rot_deg: float, mat: StandardMaterial3D, node_name: String) -> StaticBody3D:
	var body := _add_box(pos, size, mat, node_name)
	body.rotation_degrees.y = y_rot_deg
	return body


func _add_ramp(pos: Vector3, size: Vector3, angle_deg: float, mat: StandardMaterial3D, node_name: String) -> StaticBody3D:
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

	parent.add_child(body)
	return body


func _add_cylinder(pos: Vector3, radius: float, height: float, mat: StandardMaterial3D, node_name: String) -> StaticBody3D:
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

	parent.add_child(body)
	return body
