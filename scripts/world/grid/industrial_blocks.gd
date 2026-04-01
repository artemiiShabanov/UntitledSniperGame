class_name IndustrialBlocks
extends RefCounted
## All industrial-theme block builders. Each static method takes a
## BlockBuilderBase and builds the geometry + markers for that block type.
## Cell size is 15m — geometry stays within ~13m to leave natural gaps.

## ── 1. Empty Ground ──────────────────────────────────────────────────────────

static func build_empty_ground(b: BlockBuilderBase) -> void:
	# Just a concrete pad
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")


## ── 2. Ground Cover ──────────────────────────────────────────────────────────

static func build_ground_cover(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")

	# Randomized barriers and crates
	if b.maybe(0.7):
		b.add_box(
			Vector3(b.rand_offset(3.0), 0.5, b.rand_offset(3.0)),
			Vector3(3, 1, 0.5), b.mat_concrete(), "Barrier_1")
	if b.maybe(0.7):
		b.add_box(
			Vector3(b.rand_offset(3.0), 0.5, b.rand_offset(3.0)),
			Vector3(3, 1, 0.5), b.mat_concrete(), "Barrier_2")
	if b.maybe(0.6):
		b.add_box(
			Vector3(b.rand_offset(4.0), 0.5, b.rand_offset(4.0)),
			Vector3(1.5, 1, 1.5), b.mat_rust(), "Crate_1")
	if b.maybe(0.5):
		b.add_box(
			Vector3(b.rand_offset(4.0), 0.5, b.rand_offset(4.0)),
			Vector3(1.2, 0.8, 1.2), b.mat_rust(), "Crate_2")
	if b.maybe(0.4):
		b.add_box(
			Vector3(b.rand_offset(4.0), 0.75, b.rand_offset(4.0)),
			Vector3(2, 1.5, 1), b.mat_dark_metal(), "Pallet")


## ── 3. Container Stack ───────────────────────────────────────────────────────

static func build_containers(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")

	var rot1: float = b.rand_range(-15.0, 15.0)
	var c1 := b.add_box(Vector3(-1, 1.25, -2), Vector3(12, 2.5, 2.5), b.mat_rust(), "Container_1")
	c1.rotation_degrees.y = rot1

	var c2 := b.add_box(Vector3(1, 1.25, 2), Vector3(12, 2.5, 2.5), b.mat_metal(), "Container_2")
	c2.rotation_degrees.y = b.rand_range(-20.0, 20.0)

	# Maybe a stacked container
	if b.maybe(0.6):
		var c3 := b.add_box(Vector3(-1, 3.75, -2), Vector3(12, 2.5, 2.5), b.mat_dark_metal(), "Container_3")
		c3.rotation_degrees.y = rot1


## ── 4. Small Warehouse ───────────────────────────────────────────────────────

static func build_warehouse_small(b: BlockBuilderBase) -> void:
	# Main building body — ~12m wide, 8m tall, 10m deep
	b.add_box(Vector3(0, 4, 0), Vector3(12, 8, 10), b.mat_metal(), "Body")
	b.add_box(Vector3(0, 8.15, 0), Vector3(13, 0.3, 11), b.mat_dark_metal(), "Roof")
	# Loading dock
	b.add_box(Vector3(0, 0.6, 5.5), Vector3(8, 1.2, 2), b.mat_concrete(), "Dock")


## ── 5. Large Warehouse (2×1) ─────────────────────────────────────────────────

static func build_warehouse_large(b: BlockBuilderBase) -> void:
	# Spans 2 cells wide (30m) but geometry ~26m
	b.add_box(Vector3(7.5, 5, 0), Vector3(26, 10, 12), b.mat_metal(), "Body")
	b.add_box(Vector3(7.5, 10.15, 0), Vector3(28, 0.3, 14), b.mat_dark_metal(), "Roof")
	# Loading dock south face
	b.add_box(Vector3(7.5, 0.6, 7), Vector3(18, 1.2, 2), b.mat_concrete(), "Dock")
	# Roof access ladder platform on east side
	b.add_box(Vector3(20, 10.5, 0), Vector3(4, 0.3, 6), b.mat_dark_metal(), "RoofAccess")


## ── 6. Office Building ───────────────────────────────────────────────────────

static func build_office(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 3, 0), Vector3(10, 6, 8), b.mat_concrete(), "Body")
	b.add_box(Vector3(0, 6.15, 0), Vector3(11, 0.3, 9), b.mat_dark_metal(), "Roof")

	# NPC activity points inside
	b.add_activity_point(Vector3(2, 0.5, 0), ActivityPoint.Activity.OPERATE, 0.0, "office")
	b.add_activity_point(Vector3(-2, 0.5, 2), ActivityPoint.Activity.REST, 90.0, "office")


## ── 7. Silo Cluster ─────────────────────────────────────────────────────────

static func build_silo_cluster(b: BlockBuilderBase) -> void:
	# 2-3 silos with catwalks
	var count := 2 if b.maybe(0.4) else 3
	for i in range(count):
		var x := -4.0 + i * 4.0
		var h := 10.0 + i * 2.0
		b.add_cylinder(Vector3(x, h * 0.5, 0), 3.0, h, b.mat_metal(), "Silo_%d" % i)
		b.add_box(Vector3(x, h + 0.15, 0), Vector3(7, 0.3, 7), b.mat_dark_metal(), "Catwalk_%d" % i)

	# Connecting bridge
	if count >= 2:
		b.add_box(Vector3(0, 10.15, 0), Vector3(count * 4.0, 0.3, 1.5), b.mat_dark_metal(), "Bridge")


## ── 8. Crane ─────────────────────────────────────────────────────────────────

static func build_crane(b: BlockBuilderBase) -> void:
	# Crane tower
	b.add_box(Vector3(0, 12, 0), Vector3(3, 24, 3), b.mat_yellow(), "Tower")
	# Crane arm
	b.add_box(Vector3(0, 24.25, -5), Vector3(3, 0.5, 12), b.mat_yellow(), "Arm")
	# Cab platform
	b.add_box(Vector3(0, 12.25, 0), Vector3(5, 0.5, 5), b.mat_dark_metal(), "Cab")
	# Counter-weight
	b.add_box(Vector3(0, 23, 5), Vector3(3, 2.5, 3), b.mat_dark_metal(), "Weight")


## ── 9. Sniper Tower ─────────────────────────────────────────────────────────

static func build_sniper_tower(b: BlockBuilderBase) -> void:
	# Concrete pillar
	b.add_box(Vector3(0, 7.5, 0), Vector3(4, 15, 4), b.mat_concrete(), "Base")
	# Platform
	b.add_box(Vector3(0, 15.25, 0), Vector3(8, 0.5, 8), b.mat_metal(), "Platform")
	# Railings
	b.add_box(Vector3(0, 16, -3.8), Vector3(8, 1.2, 0.3), b.mat_metal(), "Rail_N")
	b.add_box(Vector3(0, 16, 3.8), Vector3(8, 1.2, 0.3), b.mat_metal(), "Rail_S")
	b.add_box(Vector3(-3.85, 16, 0), Vector3(0.3, 1.2, 8), b.mat_metal(), "Rail_W")
	b.add_box(Vector3(3.85, 16, 0), Vector3(0.3, 1.2, 8), b.mat_metal(), "Rail_E")
	# Access ramp
	b.add_ramp(Vector3(6, 7.5, 0), Vector3(4, 0.3, 20), 37.0, b.mat_dark_metal(), "Ramp")


## ── 10. Scaffolding ──────────────────────────────────────────────────────────

static func build_scaffolding(b: BlockBuilderBase) -> void:
	# Two scaffold levels
	b.add_box(Vector3(0, 4, 0), Vector3(10, 0.2, 4), b.mat_dark_metal(), "Floor_1")
	b.add_box(Vector3(0, 7, 0), Vector3(10, 0.2, 4), b.mat_dark_metal(), "Floor_2")
	# Poles
	for x_off in [-4.5, 4.5]:
		for z_off in [-1.5, 1.5]:
			b.add_box(
				Vector3(x_off, 3.5, z_off),
				Vector3(0.15, 7, 0.15), b.mat_dark_metal(), "Pole")


## ── 11. Fuel Tanks ───────────────────────────────────────────────────────────

static func build_fuel_tanks(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")
	b.add_cylinder(Vector3(-3, 2, -1), 2.5, 4, b.mat_dark_metal(), "Tank_1")
	b.add_cylinder(Vector3(3, 2, 1), 2.5, 4, b.mat_dark_metal(), "Tank_2")
	if b.maybe(0.5):
		b.add_cylinder(Vector3(0, 2, -4), 2.0, 4, b.mat_dark_metal(), "Tank_3")
	# Connecting pipes
	b.add_box(Vector3(0, 3.5, 0), Vector3(8, 0.3, 0.3), b.mat_metal(), "Pipe")


## ── 12. Enemy Rooftop ────────────────────────────────────────────────────────

static func build_enemy_rooftop(b: BlockBuilderBase) -> void:
	# Low building with accessible roof
	b.add_box(Vector3(0, 3.5, 0), Vector3(11, 7, 10), b.mat_concrete(), "Body")
	b.add_box(Vector3(0, 7.15, 0), Vector3(12, 0.3, 11), b.mat_dark_metal(), "Roof")
	# Roof railing (partial — enemies peek over)
	b.add_box(Vector3(0, 7.8, -5.3), Vector3(10, 1, 0.3), b.mat_metal(), "Railing")

	# Enemy spawns on the rooftop
	b.add_enemy_spawn(Vector3(-2, 7.5, -3), 180.0, "rooftop", "scanning")
	b.add_enemy_spawn(Vector3(3, 7.5, -2), 180.0, "rooftop", "idle")


## ── 13. Enemy Ground Post ────────────────────────────────────────────────────

static func build_enemy_ground(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")
	# Sandbag / barrier arrangement
	b.add_box(Vector3(-3, 0.6, -3), Vector3(4, 1.2, 0.6), b.mat_concrete(), "Cover_1")
	b.add_box(Vector3(3, 0.6, 2), Vector3(4, 1.2, 0.6), b.mat_concrete(), "Cover_2")
	b.add_box(Vector3(0, 0.6, 4), Vector3(0.6, 1.2, 3), b.mat_concrete(), "Cover_3")
	# Small shelter/awning
	b.add_box(Vector3(0, 2.5, -1), Vector3(5, 0.15, 4), b.mat_dark_metal(), "Awning")
	b.add_box(Vector3(-2.4, 1.25, -1), Vector3(0.15, 2.5, 0.15), b.mat_dark_metal(), "Post_L")
	b.add_box(Vector3(2.4, 1.25, -1), Vector3(0.15, 2.5, 0.15), b.mat_dark_metal(), "Post_R")

	b.add_enemy_spawn(Vector3(-2, 0.2, -2), 0.0, "ground", "patrol")
	b.add_enemy_spawn(Vector3(2, 0.2, 1), 180.0, "ground", "idle")


## ── 14. Enemy Elevated Nest ──────────────────────────────────────────────────

static func build_enemy_nest(b: BlockBuilderBase) -> void:
	# Elevated platform on stilts
	b.add_box(Vector3(0, 6.25, 0), Vector3(8, 0.5, 8), b.mat_dark_metal(), "Platform")
	# Stilts
	for x in [-3.5, 3.5]:
		for z in [-3.5, 3.5]:
			b.add_box(Vector3(x, 3, z), Vector3(0.4, 6, 0.4), b.mat_metal(), "Stilt")
	# Railing
	b.add_box(Vector3(0, 7, -3.8), Vector3(8, 1.2, 0.3), b.mat_metal(), "Rail_N")
	b.add_box(Vector3(0, 7, 3.8), Vector3(8, 1.2, 0.3), b.mat_metal(), "Rail_S")
	# Ladder (crude box)
	b.add_box(Vector3(4.5, 3, 0), Vector3(0.6, 6.5, 1.2), b.mat_dark_metal(), "Ladder")

	b.add_enemy_spawn(Vector3(-1, 6.7, -2), 180.0, "elevated", "scanning")
	b.add_enemy_spawn(Vector3(2, 6.7, 1), 0.0, "elevated", "idle")


## ── 15. NPC Work Area ────────────────────────────────────────────────────────

static func build_npc_work_area(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")
	# Workbench
	b.add_box(Vector3(-3, 0.5, -3), Vector3(4, 1, 1.5), b.mat_rust(), "Workbench")
	# Crate stacks
	b.add_box(Vector3(3, 0.5, -2), Vector3(2, 1, 2), b.mat_rust(), "Crates_1")
	b.add_box(Vector3(4, 0.5, 2), Vector3(1.5, 1, 1.5), b.mat_rust(), "Crates_2")
	if b.maybe(0.5):
		b.add_box(Vector3(3, 1.5, -2), Vector3(1.5, 1, 1.5), b.mat_dark_metal(), "Crates_3")

	b.add_activity_point(Vector3(-3, 0.2, -1), ActivityPoint.Activity.WORK, 0.0, "yard")
	b.add_activity_point(Vector3(2, 0.2, 0), ActivityPoint.Activity.CARRY, 90.0, "yard")
	b.add_activity_point(Vector3(0, 0.2, 3), ActivityPoint.Activity.INSPECT, 180.0, "yard")


## ── 16. NPC Rest Area ────────────────────────────────────────────────────────

static func build_npc_rest_area(b: BlockBuilderBase) -> void:
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_concrete(), "Pad")
	# Lean-to shelter
	b.add_box(Vector3(0, 3, -2), Vector3(8, 0.15, 6), b.mat_dark_metal(), "Roof")
	b.add_box(Vector3(-3.9, 1.5, -2), Vector3(0.2, 3, 6), b.mat_dark_metal(), "Wall_L")
	b.add_box(Vector3(3.9, 1.5, -2), Vector3(0.2, 3, 6), b.mat_dark_metal(), "Wall_R")
	# Table
	b.add_box(Vector3(0, 0.45, -2), Vector3(3, 0.9, 1.5), b.mat_rust(), "Table")
	# Bench
	b.add_box(Vector3(0, 0.3, 0), Vector3(3, 0.6, 0.8), b.mat_rust(), "Bench")

	b.add_activity_point(Vector3(0, 0.2, -1), ActivityPoint.Activity.EAT, 0.0, "rest")
	b.add_activity_point(Vector3(2, 0.2, 1), ActivityPoint.Activity.REST, 270.0, "rest")


## ── 17. Wall Segment ─────────────────────────────────────────────────────────

static func build_wall_segment(b: BlockBuilderBase) -> void:
	# Concrete wall with a gap for sightlines
	b.add_box(Vector3(-4, 1.5, 0), Vector3(5, 3, 0.5), b.mat_concrete(), "Wall_L")
	b.add_box(Vector3(4, 1.5, 0), Vector3(5, 3, 0.5), b.mat_concrete(), "Wall_R")
	# Gap in the middle (~3m) for movement and sightlines
