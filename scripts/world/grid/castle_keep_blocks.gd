class_name CastleKeepBlocks
extends RefCounted
## Medieval castle-themed block builders for grid level generation.
## Three zones: Castle (Zone 1), Battlefield (Zone 2), Enemy Camp (Zone 3).
## Cell size is 15m.

## ── ZONE 1: Castle ──────────────────────────────────────────────────────────

static func build_castle_wall(b: BlockBuilderBase) -> void:
	## Straight stone wall section with crenellations. Elevated platform for sniping.
	b.add_box(Vector3(0, 3.0, 0), Vector3(13, 6, 3), b.mat_stone(), "Wall")
	# Walkway on top.
	b.add_box(Vector3(0, 6.2, -0.5), Vector3(13, 0.4, 4), b.mat_stone_dark(), "Walkway")
	# Crenellations (merlons).
	for i in range(-5, 6, 3):
		b.add_box(Vector3(i, 7.0, 1.0), Vector3(1.5, 1.5, 0.5), b.mat_stone(), "Merlon_%d" % i)
	# Castle wall point markers along the base.
	b.add_group_marker(Vector3(-4, 0, 2), "castle_wall_points")
	b.add_group_marker(Vector3(0, 0, 2), "castle_wall_points")
	b.add_group_marker(Vector3(4, 0, 2), "castle_wall_points")


static func build_castle_tower(b: BlockBuilderBase) -> void:
	## Tower — tallest vantage point for player spawn.
	# Tower base.
	b.add_cylinder(Vector3(0, 6, 0), 3.5, 12, b.mat_stone(), "TowerBase")
	# Platform.
	b.add_box(Vector3(0, 12.2, 0), Vector3(8, 0.4, 8), b.mat_stone_dark(), "Platform")
	# Crenellations at top.
	for angle in [0, 90, 180, 270]:
		var x := 3.5 * cos(deg_to_rad(angle))
		var z := 3.5 * sin(deg_to_rad(angle))
		b.add_box(Vector3(x, 13.0, z), Vector3(1.5, 1.5, 0.5), b.mat_stone(), "Battlement_%d" % angle)
	# Castle wall point at base.
	b.add_group_marker(Vector3(0, 0, 4), "castle_wall_points")


static func build_castle_gate(b: BlockBuilderBase) -> void:
	## Gate section with arch opening. Strongest castle wall point.
	# Left wall.
	b.add_box(Vector3(-4.5, 3.0, 0), Vector3(4, 6, 3), b.mat_stone(), "GateWall_L")
	# Right wall.
	b.add_box(Vector3(4.5, 3.0, 0), Vector3(4, 6, 3), b.mat_stone(), "GateWall_R")
	# Arch top.
	b.add_box(Vector3(0, 5.0, 0), Vector3(5, 2, 3), b.mat_stone_dark(), "GateArch")
	# Gate (wooden).
	b.add_box(Vector3(0, 2.0, 0), Vector3(4, 4, 0.5), b.mat_wood_dark(), "Gate")
	# Walkway.
	b.add_box(Vector3(0, 6.2, -0.5), Vector3(13, 0.4, 4), b.mat_stone_dark(), "Walkway")
	# Multiple castle wall points.
	b.add_group_marker(Vector3(-4, 0, 2), "castle_wall_points")
	b.add_group_marker(Vector3(0, 0, 2), "castle_wall_points")
	b.add_group_marker(Vector3(4, 0, 2), "castle_wall_points")


static func build_rampart(b: BlockBuilderBase) -> void:
	## Low rampart / barricade section at castle perimeter.
	b.add_box(Vector3(0, 1.5, 0), Vector3(13, 3, 2), b.mat_stone(), "Rampart")
	# Friendly spawn behind rampart.
	b.add_group_marker(Vector3(0, 0, -3), "friendly_spawn_points")
	b.add_group_marker(Vector3(0, 0, 3), "castle_wall_points")


## ── ZONE 2: Battlefield ─────────────────────────────────────────────────────

static func build_flat_meadow(b: BlockBuilderBase) -> void:
	## Open ground — grass pad.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_grass(), "Grass")
	# Frontline point.
	b.add_group_marker(Vector3(0, 0, 0), "frontline_points")


static func build_rocky_field(b: BlockBuilderBase) -> void:
	## Open ground with scattered rocks for cover.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_grass(), "Grass")
	if b.maybe(0.8):
		b.add_box(
			Vector3(b.rand_offset(4.0), 0.75, b.rand_offset(4.0)),
			Vector3(2.5, 1.5, 2), b.mat_stone(), "Rock_1")
	if b.maybe(0.7):
		b.add_box(
			Vector3(b.rand_offset(4.0), 0.5, b.rand_offset(4.0)),
			Vector3(1.5, 1, 1.5), b.mat_stone(), "Rock_2")
	if b.maybe(0.5):
		b.add_box(
			Vector3(b.rand_offset(3.0), 0.4, b.rand_offset(3.0)),
			Vector3(3, 0.8, 1), b.mat_stone_dark(), "Rock_3")
	b.add_group_marker(Vector3(0, 0, 0), "frontline_points")


static func build_trench(b: BlockBuilderBase) -> void:
	## Trench section — lowered ground with dirt walls.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	# Trench walls.
	b.add_box(Vector3(0, 0.75, -4), Vector3(12, 1.5, 1), b.mat_dirt(), "TrenchWall_N")
	b.add_box(Vector3(0, 0.75, 4), Vector3(12, 1.5, 1), b.mat_dirt(), "TrenchWall_S")
	b.add_group_marker(Vector3(0, 0, 0), "frontline_points")


static func build_barricade_cluster(b: BlockBuilderBase) -> void:
	## Wooden barricades and hay bales.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_grass(), "Grass")
	b.add_box(Vector3(-3, 0.75, 0), Vector3(4, 1.5, 0.5), b.mat_wood(), "Barricade_1")
	b.add_box(Vector3(3, 0.75, 2), Vector3(3, 1.5, 0.5), b.mat_wood(), "Barricade_2")
	if b.maybe(0.7):
		b.add_cylinder(
			Vector3(b.rand_offset(3.0), 0.5, b.rand_offset(3.0)),
			0.8, 1.0, b.mat_wood(), "HayBale_1")
	if b.maybe(0.5):
		b.add_cylinder(
			Vector3(b.rand_offset(3.0), 0.5, b.rand_offset(3.0)),
			0.8, 1.0, b.mat_wood(), "HayBale_2")
	b.add_group_marker(Vector3(0, 0, 0), "frontline_points")


static func build_hill(b: BlockBuilderBase) -> void:
	## Elevated terrain mound.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_grass(), "Grass")
	b.add_box(Vector3(0, 1.5, 0), Vector3(8, 3, 8), b.mat_dirt(), "HillBase")
	b.add_box(Vector3(0, 3.2, 0), Vector3(6, 0.4, 6), b.mat_grass(), "HillTop")
	b.add_group_marker(Vector3(0, 3.5, 0), "frontline_points")


## ── ZONE 3: Enemy Camp ──────────────────────────────────────────────────────

static func build_enemy_camp(b: BlockBuilderBase) -> void:
	## Tent and campfire area — hostile spawn point.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	# Tent (pyramid-ish).
	b.add_box(Vector3(-2, 1.5, 0), Vector3(4, 3, 3), b.mat_banner(), "Tent")
	b.add_box(Vector3(-2, 0.5, 0), Vector3(5, 0.3, 4), b.mat_wood(), "TentBase")
	# Campfire ring.
	b.add_cylinder(Vector3(3, 0.15, 2), 0.6, 0.3, b.mat_stone_dark(), "FireRing")
	b.add_group_marker(Vector3(0, 0, 5), "hostile_spawn_points")
	b.add_group_marker(Vector3(-4, 0, 5), "hostile_spawn_points")


static func build_siege_position(b: BlockBuilderBase) -> void:
	## Siege equipment placement area.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	# Catapult frame (simplified).
	b.add_box(Vector3(0, 1.0, 0), Vector3(3, 2, 2), b.mat_wood_dark(), "CatapultBase")
	b.add_box(Vector3(0, 2.5, -1), Vector3(0.5, 3, 0.5), b.mat_wood(), "CatapultArm")
	# Palisade segments.
	b.add_box(Vector3(-5, 1.0, -3), Vector3(0.5, 2, 6), b.mat_wood(), "Palisade_L")
	b.add_box(Vector3(5, 1.0, -3), Vector3(0.5, 2, 6), b.mat_wood(), "Palisade_R")
	b.add_group_marker(Vector3(0, 0, 5), "hostile_spawn_points")
	# Destructible spawn for siege equipment.
	b.add_destructible_spawn(Vector3(0, 2, 0))


static func build_archer_post(b: BlockBuilderBase) -> void:
	## Elevated platform for ranged enemies.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	# Wooden platform.
	b.add_box(Vector3(0, 2.0, 0), Vector3(5, 0.3, 5), b.mat_wood(), "Platform")
	# Support legs.
	b.add_box(Vector3(-2, 1.0, -2), Vector3(0.4, 2, 0.4), b.mat_wood_dark(), "Leg_1")
	b.add_box(Vector3(2, 1.0, -2), Vector3(0.4, 2, 0.4), b.mat_wood_dark(), "Leg_2")
	b.add_box(Vector3(-2, 1.0, 2), Vector3(0.4, 2, 0.4), b.mat_wood_dark(), "Leg_3")
	b.add_box(Vector3(2, 1.0, 2), Vector3(0.4, 2, 0.4), b.mat_wood_dark(), "Leg_4")
	b.add_group_marker(Vector3(0, 0, 5), "hostile_spawn_points")


static func build_palisade_wall(b: BlockBuilderBase) -> void:
	## Wooden palisade wall — enemy perimeter.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	b.add_box(Vector3(0, 1.5, 0), Vector3(12, 3, 0.5), b.mat_wood(), "Palisade")
	# Pointed tops.
	for i in range(-5, 6, 2):
		b.add_box(Vector3(i, 3.3, 0), Vector3(0.3, 0.6, 0.3), b.mat_wood_dark(), "Spike_%d" % i)
	b.add_group_marker(Vector3(0, 0, 5), "hostile_spawn_points")


static func build_spawn_area(b: BlockBuilderBase) -> void:
	## Open spawn area at enemy edge.
	b.add_box(Vector3(0, 0.02, 0), Vector3(13, 0.04, 13), b.mat_dirt(), "Ground")
	b.add_group_marker(Vector3(-3, 0, 0), "hostile_spawn_points")
	b.add_group_marker(Vector3(0, 0, 0), "hostile_spawn_points")
	b.add_group_marker(Vector3(3, 0, 0), "hostile_spawn_points")
	# Destructible powder keg spawn.
	if b.maybe(0.4):
		b.add_destructible_spawn(Vector3(b.rand_offset(3.0), 0, b.rand_offset(3.0)))
