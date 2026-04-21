extends BaseLevel
## Castle Keep — grid-based procedural medieval level.
## Three-zone layout: Castle (rows 0-2), Battlefield (rows 3-9), Enemy Camp (rows 10-14).
## Player spawns on a castle tower with a view of the entire battlefield.

func _ready() -> void:
	_build_grid_level()
	super._ready()


func _build_grid_level() -> void:
	var grid_data := _create_grid_level_data()
	var builder := GridLevelBuilder.new()
	var result := builder.build(grid_data, self)

	if not result.success:
		for w in result.warnings:
			push_warning("CastleKeep: %s" % w)

	_create_player_spawn(result)
	_create_extraction_zones(result)


## ── Grid Data ───────────────────────────────────────────────────────────────

func _create_grid_level_data() -> GridLevelData:
	var data := GridLevelData.new()
	if level_data:
		data.level_name = level_data.level_name
		data.scene_path = level_data.scene_path
		data.castle_hp = level_data.castle_hp
		data.extraction_count = level_data.extraction_count
		data.level_ambient = level_data.level_ambient
		data.level_theme = level_data.level_theme
		data.available_times_of_day = level_data.available_times_of_day
		data.available_weather = level_data.available_weather

	data.block_catalog = _create_catalog()
	data.level_rules = _create_rules()
	return data


## ── Block Catalog ───────────────────────────────────────────────────────────

func _create_catalog() -> BlockCatalog:
	var cat := BlockCatalog.new()
	cat.catalog_name = "castle_keep"
	cat.blocks = [
		# Zone 1: Castle
		BlockDef.create("castle_wall", "Castle Wall", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.CASTLE,
			["castle"], 2.0, Vector2i(1, 1), -1, true, false, true),
		BlockDef.create("castle_tower", "Castle Tower", null,
			BlockDef.HeightType.TOWER, BlockDef.BlockType.SNIPER_NEST,
			["castle", "vantage"], 1.0, Vector2i(1, 1), 2, false, true),
		BlockDef.create("castle_gate", "Castle Gate", null,
			BlockDef.HeightType.MEDIUM, BlockDef.BlockType.CASTLE,
			["castle", "gate"], 0.5, Vector2i(1, 1), 1, true),
		BlockDef.create("rampart", "Rampart", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.CASTLE,
			["castle"], 1.5, Vector2i(1, 1), -1, true, false, true),

		# Zone 2: Battlefield
		BlockDef.create("flat_meadow", "Flat Meadow", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.BATTLEFIELD,
			["battlefield"], 3.0, Vector2i(1, 1), -1, true),
		BlockDef.create("rocky_field", "Rocky Field", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.BATTLEFIELD,
			["battlefield", "cover"], 2.0, Vector2i(1, 1), -1, true),
		BlockDef.create("trench", "Trench", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.BATTLEFIELD,
			["battlefield", "cover"], 1.0, Vector2i(1, 1), 4, true),
		BlockDef.create("barricade_cluster", "Barricade Cluster", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.BATTLEFIELD,
			["battlefield", "cover"], 1.5, Vector2i(1, 1), 6, true),
		BlockDef.create("hill", "Hill", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.BATTLEFIELD,
			["battlefield"], 0.8, Vector2i(1, 1), 3, true),

		# Zone 3: Enemy Camp
		BlockDef.create("enemy_camp", "Enemy Camp", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.ENEMY_CAMP,
			["enemy"], 2.0, Vector2i(1, 1), 6, true),
		BlockDef.create("siege_position", "Siege Position", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.ENEMY_CAMP,
			["enemy", "siege"], 1.0, Vector2i(1, 1), 3, true),
		BlockDef.create("archer_post", "Archer Post", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.ENEMY_CAMP,
			["enemy", "ranged"], 1.0, Vector2i(1, 1), 3, true),
		BlockDef.create("palisade_wall", "Palisade Wall", null,
			BlockDef.HeightType.LOW, BlockDef.BlockType.ENEMY_CAMP,
			["enemy", "wall"], 1.5, Vector2i(1, 1), -1, true),
		BlockDef.create("spawn_area", "Spawn Area", null,
			BlockDef.HeightType.GROUND, BlockDef.BlockType.ENEMY_CAMP,
			["enemy", "spawn"], 2.5, Vector2i(1, 1), -1, true),
	]
	return cat


## ── Level Rules ─────────────────────────────────────────────────────────────

func _create_rules() -> GridLevelRules:
	var rules := GridLevelRules.new()
	rules.grid_width = 10
	rules.grid_depth = 15
	rules.cell_size = 15.0
	rules.sightline_max_height = BlockDef.HeightType.LOW

	# ── Anchors: castle tower in castle zone ──
	var anchor1 := AnchorPlacement.new()
	anchor1.block_type_filter = BlockDef.BlockType.SNIPER_NEST
	anchor1.zone_shape = ZoneRule.ZoneShape.RECT
	anchor1.zone_rect = Rect2i(0, 0, 10, 2)  # Castle zone (rows 0-1)
	anchor1.min_distance_to_anchors = 4
	anchor1.facing_mode = AnchorPlacement.FacingMode.INWARD
	anchor1.required = true

	rules.anchor_placements = [anchor1]

	# ── Zone Rules ──
	# Zone 1: Castle (rows 0-1) — only castle + sniper_nest blocks
	var castle_zone := ZoneRule.new()
	castle_zone.shape = ZoneRule.ZoneShape.RECT
	castle_zone.rect = Rect2i(0, 0, 10, 2)
	castle_zone.allowed_types = [
		BlockDef.BlockType.CASTLE,
		BlockDef.BlockType.SNIPER_NEST,
	]

	# Zone 2: Battlefield (rows 2-11) — battlefield blocks only
	var battlefield_zone := ZoneRule.new()
	battlefield_zone.shape = ZoneRule.ZoneShape.RECT
	battlefield_zone.rect = Rect2i(0, 2, 10, 10)
	battlefield_zone.allowed_types = [
		BlockDef.BlockType.BATTLEFIELD,
		BlockDef.BlockType.EMPTY,
	]

	# Zone 3: Enemy Camp (rows 12-14) — enemy blocks only
	var enemy_zone := ZoneRule.new()
	enemy_zone.shape = ZoneRule.ZoneShape.RECT
	enemy_zone.rect = Rect2i(0, 12, 10, 3)
	enemy_zone.allowed_types = [
		BlockDef.BlockType.ENEMY_CAMP,
	]

	rules.zone_rules = [castle_zone, battlefield_zone, enemy_zone]

	# ── Height neighbor rules ──
	var no_tower_neighbors := HeightNeighborRule.new()
	no_tower_neighbors.source_height = BlockDef.HeightType.TOWER
	no_tower_neighbors.forbidden_neighbor_heights = [
		BlockDef.HeightType.TOWER,
		BlockDef.HeightType.TALL,
	]

	rules.height_neighbor_rules = [no_tower_neighbors]

	# ── Block budgets ──
	var min_enemy_blocks := BlockBudget.new()
	min_enemy_blocks.filter_by = BlockBudget.FilterBy.BLOCK_TYPE
	min_enemy_blocks.filter_value = "ENEMY_CAMP"
	min_enemy_blocks.min_count = 5
	min_enemy_blocks.max_count = 15

	var min_castle_blocks := BlockBudget.new()
	min_castle_blocks.filter_by = BlockBudget.FilterBy.BLOCK_TYPE
	min_castle_blocks.filter_value = "CASTLE"
	min_castle_blocks.min_count = 4
	min_castle_blocks.max_count = 10

	rules.block_budgets = [min_enemy_blocks, min_castle_blocks]

	rules.soft_constraint_relaxation_order = [
		"height_neighbor", "budget_max", "zone"
	]

	return rules


## ── Player Spawn ────────────────────────────────────────────────────────────

func _create_player_spawn(result: GridBuildResult) -> void:
	if result.player_spawn_block:
		_add_spawn(
			result.player_spawn_block.position + Vector3(0, 12.5, 0),
			SpawnPoint.Type.PLAYER, 0.0)
	else:
		push_warning("CastleKeep: no player spawn — using castle center fallback")
		_add_spawn(Vector3(6 * 15.0, 7.0, 1 * 15.0), SpawnPoint.Type.PLAYER, 0.0)


## ── Extraction Zones ────────────────────────────────────────────────────────

func _create_extraction_zones(result: GridBuildResult) -> void:
	var extraction_scene := preload("res://scenes/world/extraction_zone.tscn")

	if result.extraction_blocks.is_empty():
		# Fallback: place in castle zone.
		var ez := extraction_scene.instantiate()
		ez.name = "ExtractionZone_Fallback"
		ez.position = Vector3(6 * 15.0, 0, 1 * 15.0)
		add_child(ez)
		return

	for i in range(result.extraction_blocks.size()):
		var ez := extraction_scene.instantiate()
		ez.name = "ExtractionZone_%d" % (i + 1)
		# Raise to wall walkway level — castle_wall walkway is at ~6.2, rampart at ~1.5.
		var block: Node3D = result.extraction_blocks[i]
		var is_wall := block.name.begins_with("castle_wall")
		var y_offset := 6.5 if is_wall else 3.2
		ez.position = block.position + Vector3(0, y_offset, 0)
		add_child(ez)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _add_spawn(pos: Vector3, type: SpawnPoint.Type, facing: float) -> void:
	var sp := SpawnPoint.new()
	sp.name = "Spawn_%s" % SpawnPoint.Type.keys()[type]
	sp.spawn_type = type
	sp.position = pos
	sp.facing_direction = facing
	add_child(sp)
