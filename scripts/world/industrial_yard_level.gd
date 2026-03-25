extends BaseLevel
## Industrial Yard — first real level.
## Procedurally builds geometry via IndustrialYardBuilder, then sets up
## spawn points, extraction zones, and ziplines.

var builder: IndustrialYardBuilder


func _ready() -> void:
	_build_level()
	super._ready()


func _build_level() -> void:
	builder = IndustrialYardBuilder.new()
	builder.build(self)

	_create_spawn_points()
	_create_extraction_zones()
	_create_ziplines()
	_create_activity_points()


## ── Spawn Points ───────────────────────────────────────────────────────────

func _create_spawn_points() -> void:
	# Player spawn — on top of the observation tower
	_add_spawn("PlayerSpawn", SpawnPoint.Type.PLAYER, Vector3(0, 15.8, 80), 0.0)

	# ── Enemy spawns ──
	# Design: all 80m+ from player tower at (0, 15.8, 80)
	# Player looks north (negative Z), enemies are in the yard below and ahead

	# Warehouse A roof and dock area (~120m from player)
	_add_spawn("ES_WarehouseA_Roof1", SpawnPoint.Type.ENEMY,
		Vector3(-10, 10.5, -40), 180.0, "rooftop", "scanning")
	_add_spawn("ES_WarehouseA_Roof2", SpawnPoint.Type.ENEMY,
		Vector3(15, 10.5, -40), 180.0, "rooftop", "idle")
	_add_spawn("ES_WarehouseA_Dock", SpawnPoint.Type.ENEMY,
		Vector3(5, 1.5, -26), 180.0, "ground", "scanning")

	# Warehouse B area (~150m from player)
	_add_spawn("ES_WarehouseB_Roof", SpawnPoint.Type.ENEMY,
		Vector3(65, 8.5, -50), 210.0, "rooftop", "scanning")
	_add_spawn("ES_WarehouseB_Ground", SpawnPoint.Type.ENEMY,
		Vector3(55, 0.3, -40), 200.0, "ground", "idle")

	# Warehouse C area (~170m from player)
	_add_spawn("ES_WarehouseC_Roof", SpawnPoint.Type.ENEMY,
		Vector3(-50, 10.5, -70), 160.0, "rooftop", "scanning")
	_add_spawn("ES_WarehouseC_Ground", SpawnPoint.Type.ENEMY,
		Vector3(-45, 0.3, -58), 180.0, "ground", "idle")

	# Silo catwalks (~175m from player)
	_add_spawn("ES_Silo_Top1", SpawnPoint.Type.ENEMY,
		Vector3(-80, 12.5, -60), 150.0, "elevated", "scanning")
	_add_spawn("ES_Silo_Top2", SpawnPoint.Type.ENEMY,
		Vector3(-68, 14.5, -60), 160.0, "elevated", "idle")

	# Crane area (~100m from player, elevated)
	_add_spawn("ES_Crane_Cab", SpawnPoint.Type.ENEMY,
		Vector3(80, 12.5, 20), 240.0, "elevated", "scanning")
	_add_spawn("ES_Crane_Arm", SpawnPoint.Type.ENEMY,
		Vector3(80, 24.5, 0), 220.0, "elevated", "idle")

	# Yard ground level — scattered (~100-140m from player)
	_add_spawn("ES_Yard_Center", SpawnPoint.Type.ENEMY,
		Vector3(0, 0.3, -10), 180.0, "ground", "idle")
	_add_spawn("ES_Yard_East", SpawnPoint.Type.ENEMY,
		Vector3(40, 0.3, 10), 200.0, "ground", "scanning")
	_add_spawn("ES_Yard_West", SpawnPoint.Type.ENEMY,
		Vector3(-30, 0.3, -20), 160.0, "ground", "idle")

	# Far north — extreme range (~200m+ from player)
	_add_spawn("ES_FarNorth1", SpawnPoint.Type.ENEMY,
		Vector3(20, 0.3, -120), 180.0, "ground", "idle")
	_add_spawn("ES_FarNorth2", SpawnPoint.Type.ENEMY,
		Vector3(-30, 0.3, -110), 170.0, "ground", "scanning")

	# Office building roof (~100m from player)
	_add_spawn("ES_Office_Roof", SpawnPoint.Type.ENEMY,
		Vector3(25, 6.5, -20), 190.0, "rooftop", "scanning")


func _add_spawn(spawn_name: String, type: SpawnPoint.Type, pos: Vector3,
		facing: float, group: String = "", behavior: String = "default") -> void:
	var sp := SpawnPoint.new()
	sp.name = spawn_name
	sp.spawn_type = type
	sp.position = pos
	sp.facing_direction = facing
	sp.spawn_group = group
	sp.behavior_tag = behavior
	add_child(sp)


## ── Extraction Zones ───────────────────────────────────────────────────────

func _create_extraction_zones() -> void:
	var extraction_scene := preload("res://scenes/world/extraction_zone.tscn")

	# Extraction 1 — far northwest corner (long trek from tower)
	var ez1 := extraction_scene.instantiate()
	ez1.name = "ExtractionZone1"
	ez1.position = Vector3(-120, 0, -120)
	add_child(ez1)

	# Extraction 2 — east side near crane base
	var ez2 := extraction_scene.instantiate()
	ez2.name = "ExtractionZone2"
	ez2.position = Vector3(120, 0, 40)
	add_child(ez2)

	# Extraction 3 — south-west (closest to player but still requires descent)
	var ez3 := extraction_scene.instantiate()
	ez3.name = "ExtractionZone3"
	ez3.position = Vector3(-80, 0, 60)
	add_child(ez3)


## ── Activity Points (NPC behavior locations) ─────────────────────────────

func _create_activity_points() -> void:
	# ── WORK points (Laborers hammer/lift here) ──
	# Near warehouse A loading dock — manual labor
	_add_activity("AP_Work_Dock1", ActivityPoint.Activity.WORK,
		Vector3(-5, 1.8, -25), 0.0)
	_add_activity("AP_Work_Dock2", ActivityPoint.Activity.WORK,
		Vector3(8, 1.8, -25), 180.0)
	# Near containers — loading/unloading
	_add_activity("AP_Work_Containers", ActivityPoint.Activity.WORK,
		Vector3(-12, 0.3, -20), 90.0)
	# Near warehouse C — maintenance work
	_add_activity("AP_Work_WarehouseC", ActivityPoint.Activity.WORK,
		Vector3(-42, 0.3, -60), 180.0)

	# ── CARRY points (Laborers walk between these and work points) ──
	# Yard center — transit route
	_add_activity("AP_Carry_YardCenter", ActivityPoint.Activity.CARRY,
		Vector3(5, 0.3, -5), 0.0)
	# Near fuel tanks — delivering supplies
	_add_activity("AP_Carry_FuelTanks", ActivityPoint.Activity.CARRY,
		Vector3(38, 0.3, 8), 270.0)
	# Between warehouses A and B
	_add_activity("AP_Carry_EastPath", ActivityPoint.Activity.CARRY,
		Vector3(35, 0.3, -30), 0.0)

	# ── OPERATE points (Technicians use equipment here) ──
	# Silo control area
	_add_activity("AP_Operate_Silos", ActivityPoint.Activity.OPERATE,
		Vector3(-72, 0.3, -52), 180.0)
	# Near office building — control panel
	_add_activity("AP_Operate_Office", ActivityPoint.Activity.OPERATE,
		Vector3(20, 0.3, -16), 0.0)
	# Near crane base — crane controls
	_add_activity("AP_Operate_Crane", ActivityPoint.Activity.OPERATE,
		Vector3(76, 0.3, 18), 90.0)

	# ── INSPECT points (Technicians walk between equipment) ──
	# Fuel tank inspection
	_add_activity("AP_Inspect_FuelTanks", ActivityPoint.Activity.INSPECT,
		Vector3(42, 0.3, 14), 180.0)
	# Warehouse B exterior — checking equipment
	_add_activity("AP_Inspect_WarehouseB", ActivityPoint.Activity.INSPECT,
		Vector3(50, 0.3, -42), 90.0)

	# ── WALK points (Civilians stroll between these) ──
	# Yard east path
	_add_activity("AP_Walk_East", ActivityPoint.Activity.WALK,
		Vector3(30, 0.3, 5), 0.0)
	# Yard west path
	_add_activity("AP_Walk_West", ActivityPoint.Activity.WALK,
		Vector3(-25, 0.3, -10), 180.0)
	# Near office
	_add_activity("AP_Walk_Office", ActivityPoint.Activity.WALK,
		Vector3(18, 0.3, -22), 270.0)
	# Far north path
	_add_activity("AP_Walk_North", ActivityPoint.Activity.WALK,
		Vector3(0, 0.3, -100), 180.0)

	# ── EAT points (Civilians sit/eat here) ──
	# Near warehouse A dock — lunch spot
	_add_activity("AP_Eat_Dock", ActivityPoint.Activity.EAT,
		Vector3(12, 0.3, -18), 0.0)
	# Near office — break area
	_add_activity("AP_Eat_Office", ActivityPoint.Activity.EAT,
		Vector3(30, 0.3, -18), 270.0)

	# ── REST points (shared — all types use these) ──
	# Near containers — smoke break spot
	_add_activity("AP_Rest_Containers", ActivityPoint.Activity.REST,
		Vector3(-18, 0.3, -15), 90.0)
	# Near warehouse B — break area
	_add_activity("AP_Rest_WarehouseB", ActivityPoint.Activity.REST,
		Vector3(52, 0.3, -36), 0.0)
	# South yard — near player tower (visible from above)
	_add_activity("AP_Rest_SouthYard", ActivityPoint.Activity.REST,
		Vector3(-10, 0.3, 30), 180.0)
	# Near silos
	_add_activity("AP_Rest_Silos", ActivityPoint.Activity.REST,
		Vector3(-65, 0.3, -48), 0.0)

	# ── IDLE points (Civilians loiter here) ──
	# Yard center — standing around
	_add_activity("AP_Idle_YardCenter", ActivityPoint.Activity.IDLE,
		Vector3(-5, 0.3, 0), 180.0)
	# Near barriers — watching the yard
	_add_activity("AP_Idle_Barriers", ActivityPoint.Activity.IDLE,
		Vector3(20, 0.3, -13), 0.0)


func _add_activity(point_name: String, activity: ActivityPoint.Activity,
		pos: Vector3, facing: float, group: String = "") -> void:
	var ap := ActivityPoint.new()
	ap.name = point_name
	ap.activity = activity
	ap.position = pos
	ap.facing_direction = facing
	ap.point_group = group
	add_child(ap)


## ── Ziplines ───────────────────────────────────────────────────────────────

func _create_ziplines() -> void:
	var zipline_scene := preload("res://scenes/world/zipline.tscn")

	# Zipline 1: Player tower → west platform (repositioning)
	var z1 := zipline_scene.instantiate()
	z1.name = "Zipline_Tower_West"
	z1.point_a = Vector3(-2, 15.5, 78)
	z1.point_b = Vector3(-58, 10, 60)
	add_child(z1)

	# Zipline 2: Player tower → crane cab (cross the yard)
	var z2 := zipline_scene.instantiate()
	z2.name = "Zipline_Tower_Crane"
	z2.point_a = Vector3(2, 15.5, 78)
	z2.point_b = Vector3(78, 12.5, 22)
	add_child(z2)

	# Zipline 3: West platform → warehouse C roof
	var z3 := zipline_scene.instantiate()
	z3.name = "Zipline_West_WarehouseC"
	z3.point_a = Vector3(-60, 10, 58)
	z3.point_b = Vector3(-55, 10.5, -58)
	add_child(z3)
