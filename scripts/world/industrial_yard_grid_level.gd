extends BaseLevel
## Industrial Yard — grid-based procedural version.
## Replaces IndustrialYardBuilder with the grid generation system.
## Geometry is built from 17 block types placed by GridLevelBuilder.

func _ready() -> void:
	_build_grid_level()
	super._ready()


func _build_grid_level() -> void:
	var grid_data := _create_grid_level_data()
	var builder := GridLevelBuilder.new()
	var result := builder.build(grid_data, self)

	if not result.success:
		for w in result.warnings:
			push_warning("GridLevel: %s" % w)

	_create_player_spawn(result)
	_create_extraction_zones(result)
	_create_ziplines(result)


## ── Grid Data (catalog + rules) ──────────────────────────────────────────────

func _create_grid_level_data() -> GridLevelData:
	var data := GridLevelData.new()
	# Copy fields from the inspector-assigned level_data
	if level_data:
		data.level_name = level_data.level_name
		data.scene_path = level_data.scene_path
		data.enemy_pool = level_data.enemy_pool
		data.enemy_count_range = level_data.enemy_count_range
		data.extraction_count = level_data.extraction_count
		data.npc_pool = level_data.npc_pool
		data.npc_count_range = level_data.npc_count_range
		data.level_events_pool = level_data.level_events_pool
		data.max_events_per_run = level_data.max_events_per_run
		data.level_ambient = level_data.level_ambient
		data.level_theme = level_data.level_theme
		data.available_times_of_day = level_data.available_times_of_day
		data.available_weather = level_data.available_weather
		data.early_phase_duration = level_data.early_phase_duration
		data.mid_phase_duration = level_data.mid_phase_duration
		data.mid_spawn_interval = level_data.mid_spawn_interval
		data.late_spawn_interval = level_data.late_spawn_interval
		data.mid_max_enemies = level_data.mid_max_enemies
		data.late_max_enemies = level_data.late_max_enemies

	data.block_catalog = _create_catalog()
	data.level_rules = _create_rules()
	return data


## ── Block Catalog ────────────────────────────────────────────────────────────

func _create_catalog() -> BlockCatalog:
	var cat := BlockCatalog.new()
	cat.catalog_name = "industrial"
	cat.blocks = [
		# Ground fillers (high weight — most of the map)
		# empty_ground and ground_cover can host extraction zones
		BlockDef.create("empty_ground", "Empty Ground", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.EMPTY,
			[], 3.0, Vector2i(1, 1), -1, false, false, true),
		BlockDef.create("ground_cover", "Ground Cover", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.PROPS,
			["cover"], 2.5, Vector2i(1, 1), -1, true, false, true),

		# Low structures
		BlockDef.create("containers", "Container Stack", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.PROPS,
			["cover", "industrial"], 1.5, Vector2i(1, 1), -1, true),
		BlockDef.create("scaffolding", "Scaffolding", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.PROPS,
			["industrial"], 0.8),
		BlockDef.create("fuel_tanks", "Fuel Tanks", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.PROPS,
			["industrial"], 0.6, Vector2i(1, 1), 2),
		BlockDef.create("wall_segment", "Wall Segment", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.PROPS,
			["wall"], 0.5),

		# Medium structures
		BlockDef.create("warehouse_small", "Small Warehouse", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.PROPS,
			["warehouse", "industrial"], 1.0, Vector2i(1, 1), 4),
		BlockDef.create("warehouse_large", "Large Warehouse", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.PROPS,
			["warehouse", "industrial"], 0.5, Vector2i(2, 1), 2),
		BlockDef.create("office", "Office Building", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.NPC,
			["building"], 0.5, Vector2i(1, 1), 2),

		# Tall structures
		BlockDef.create("silo_cluster", "Silo Cluster", null,
			BlockDef.HeightType.TALL, BlockDef.BlockType.PROPS,
			["industrial"], 0.6, Vector2i(1, 1), 2),

		# Tower structures
		BlockDef.create("crane", "Crane", null,
			BlockDef.HeightType.TOWER, BlockDef.BlockType.PROPS,
			["industrial"], 0.3, Vector2i(1, 1), 1),

		# Sniper nests — player can spawn here
		BlockDef.create("sniper_tower", "Sniper Tower", null,
			BlockDef.HeightType.TOWER, BlockDef.BlockType.SNIPER_NEST,
			["vantage"], 1.0, Vector2i(1, 1), 3, false, true),

		# Enemy blocks
		BlockDef.create("enemy_rooftop", "Enemy Rooftop", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.ENEMY,
			["enemy"], 1.0, Vector2i(1, 1), 5),
		BlockDef.create("enemy_ground", "Enemy Ground Post", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.ENEMY,
			["enemy"], 1.2, Vector2i(1, 1), 6),
		BlockDef.create("enemy_nest", "Enemy Elevated Nest", null,
			BlockDef.HeightType.TALL, BlockDef.BlockType.ENEMY,
			["enemy", "elevated"], 0.8, Vector2i(1, 1), 3),

		# NPC blocks
		BlockDef.create("npc_work_area", "NPC Work Area", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.NPC,
			["npc"], 0.8, Vector2i(1, 1), 4),
		BlockDef.create("npc_rest_area", "NPC Rest Area", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.NPC,
			["npc"], 0.6, Vector2i(1, 1), 3),
	]
	return cat


## ── Level Rules ──────────────────────────────────────────────────────────────

func _create_rules() -> GridLevelRules:
	var rules := GridLevelRules.new()
	rules.grid_width = 15
	rules.grid_depth = 15
	rules.cell_size = 15.0
	rules.sightline_max_height = BlockDef.HeightType.LOW

	# ── Anchors: 2 sniper nests in outer ring, well-separated ──
	var anchor1 := AnchorPlacement.new()
	anchor1.block_type_filter = BlockDef.BlockType.SNIPER_NEST
	anchor1.zone_shape = ZoneRule.ZoneShape.RING
	anchor1.zone_ring_index = 0  # Outermost ring
	anchor1.min_distance_to_anchors = 6
	anchor1.facing_mode = AnchorPlacement.FacingMode.INWARD
	anchor1.required = true

	var anchor2 := AnchorPlacement.new()
	anchor2.block_type_filter = BlockDef.BlockType.SNIPER_NEST
	anchor2.zone_shape = ZoneRule.ZoneShape.RING
	anchor2.zone_ring_index = 1  # Second ring
	anchor2.min_distance_to_anchors = 6
	anchor2.facing_mode = AnchorPlacement.FacingMode.INWARD
	anchor2.required = true

	rules.anchor_placements = [anchor1, anchor2]

	# ── Zone rules ──
	# Outer ring: ground only
	var outer_ring := ZoneRule.new()
	outer_ring.shape = ZoneRule.ZoneShape.RING
	outer_ring.ring_index = 0
	outer_ring.allowed_heights = [
		BlockDef.HeightType.GROUND,
		BlockDef.HeightType.LOW,
	]

	# Inner core (ring 5+): allow everything
	# No explicit rule needed — defaults to unrestricted

	rules.zone_rules = [outer_ring]

	# ── Height neighbor rules ──
	# No two TALL+ blocks adjacent
	var no_tall_neighbors := HeightNeighborRule.new()
	no_tall_neighbors.source_height = BlockDef.HeightType.TALL
	no_tall_neighbors.forbidden_neighbor_heights = [
		BlockDef.HeightType.TALL,
		BlockDef.HeightType.TOWER,
	]

	# No two TOWER blocks adjacent
	var no_tower_neighbors := HeightNeighborRule.new()
	no_tower_neighbors.source_height = BlockDef.HeightType.TOWER
	no_tower_neighbors.forbidden_neighbor_heights = [
		BlockDef.HeightType.TALL,
		BlockDef.HeightType.TOWER,
		BlockDef.HeightType.MEDIUM,
	]

	rules.height_neighbor_rules = [no_tall_neighbors, no_tower_neighbors]

	# ── Block budgets ──
	# At least 6 enemy blocks
	var min_enemies := BlockBudget.new()
	min_enemies.filter_by = BlockBudget.FilterBy.BLOCK_TYPE
	min_enemies.filter_value = "ENEMY"
	min_enemies.min_count = 6
	min_enemies.max_count = 12

	# At least 3 NPC blocks
	var min_npcs := BlockBudget.new()
	min_npcs.filter_by = BlockBudget.FilterBy.BLOCK_TYPE
	min_npcs.filter_value = "NPC"
	min_npcs.min_count = 3
	min_npcs.max_count = 8

	# Max 10 TALL/TOWER blocks total
	var max_tall := BlockBudget.new()
	max_tall.filter_by = BlockBudget.FilterBy.HEIGHT_TYPE
	max_tall.filter_value = "TALL"
	max_tall.max_count = 6

	var max_tower := BlockBudget.new()
	max_tower.filter_by = BlockBudget.FilterBy.HEIGHT_TYPE
	max_tower.filter_value = "TOWER"
	max_tower.max_count = 4

	rules.block_budgets = [min_enemies, min_npcs, max_tall, max_tower]

	return rules


## ── Player Spawn ─────────────────────────────────────────────────────────────
## Placed on the block chosen by the solver (is_player_spawn = true).

func _create_player_spawn(result: GridBuildResult) -> void:
	if result.player_spawn_block:
		# Sniper tower platform is at Y=15.25 — spawn slightly above
		_add_spawn(
			result.player_spawn_block.position + Vector3(0, 15.8, 0),
			SpawnPoint.Type.PLAYER, 0.0)
	else:
		# Fallback: center of map at ground level
		push_warning("GridLevel: no player spawn block found — using center fallback")
		_add_spawn(Vector3(7 * 15.0, 0.5, 7 * 15.0), SpawnPoint.Type.PLAYER, 0.0)


## ── Extraction Zones ─────────────────────────────────────────────────────────
## Placed on blocks chosen by the solver (is_extraction_zone = true).

func _create_extraction_zones(result: GridBuildResult) -> void:
	var extraction_scene := preload("res://scenes/world/extraction_zone.tscn")

	if result.extraction_blocks.is_empty():
		push_warning("GridLevel: no extraction blocks found — using corner fallback")
		var ez := extraction_scene.instantiate()
		ez.name = "ExtractionZone_Fallback"
		ez.position = Vector3(15.0, 0, 15.0)
		add_child(ez)
		return

	for i in range(result.extraction_blocks.size()):
		var ez := extraction_scene.instantiate()
		ez.name = "ExtractionZone_%d" % (i + 1)
		ez.position = result.extraction_blocks[i].position
		add_child(ez)


## ── Ziplines ─────────────────────────────────────────────────────────────────
## Connect sniper towers to each other or to interesting vantage points.

func _create_ziplines(result: GridBuildResult) -> void:
	var zipline_scene := preload("res://scenes/world/zipline.tscn")
	var towers := _find_nodes_by_name_prefix("sniper_tower_")

	if towers.size() >= 2:
		var z1 := zipline_scene.instantiate()
		z1.name = "Zipline_Towers"
		z1.point_a = towers[0].position + Vector3(0, 15.5, 0)
		z1.point_b = towers[1].position + Vector3(0, 15.5, 0)
		add_child(z1)

	var cranes := _find_nodes_by_name_prefix("crane_")
	if not cranes.is_empty() and not towers.is_empty():
		var z2 := zipline_scene.instantiate()
		z2.name = "Zipline_Tower_Crane"
		z2.point_a = towers[0].position + Vector3(0, 15.5, 0)
		z2.point_b = cranes[0].position + Vector3(0, 12.5, 0)
		add_child(z2)


## ── Helpers ──────────────────────────────────────────────────────────────────

func _add_spawn(pos: Vector3, type: SpawnPoint.Type, facing: float) -> void:
	var sp := SpawnPoint.new()
	sp.name = "Spawn_%s" % SpawnPoint.Type.keys()[type]
	sp.spawn_type = type
	sp.position = pos
	sp.facing_direction = facing
	add_child(sp)


func _find_nodes_by_name_prefix(prefix: String) -> Array[Node3D]:
	var found: Array[Node3D] = []
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node := stack.pop_back()
		if node is Node3D and node.name.begins_with(prefix):
			found.append(node as Node3D)
		for child in node.get_children():
			stack.append(child)
	return found
