class_name GridLevelBuilder
extends RefCounted
## Constraint-based grid solver for procedural level generation.
## Takes a GridLevelData, fills a grid with blocks from the catalog
## respecting all rules, and returns instantiated scenes.
##
## Algorithm:
##   1. Initialize grid, stamp zone constraints
##   2. Place anchors (randomized within allowed zones)
##   3. Generate sightline lanes from sniper nest positions
##   4. Fill remaining cells (most-constrained-first)
##   5. Enforce block budgets
##   6. Instantiate block scenes

## ── Types ────────────────────────────────────────────────────────────────────

## Internal cell state during solving
class GridCell:
	var coord: Vector2i
	var block_def: BlockDef = null
	var locked: bool = false  ## Anchors and multi-cell occupants
	var sightline_restricted: bool = false
	## Accumulated zone constraints (intersection of overlapping rules)
	var allowed_heights: Array[BlockDef.HeightType] = []
	var allowed_types: Array[BlockDef.BlockType] = []
	var forbidden_tags: PackedStringArray = []
	## Soft zone constraints (can be relaxed)
	var soft_allowed_heights: Array[BlockDef.HeightType] = []
	var soft_allowed_types: Array[BlockDef.BlockType] = []

	func is_occupied() -> bool:
		return block_def != null


const NEIGHBORS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## ── State ────────────────────────────────────────────────────────────────────

var _grid: Array = []  ## Array[Array[GridCell]]
var _rules: GridLevelRules
var _catalog: BlockCatalog
var _rng: RandomNumberGenerator
var _anchor_positions: Array[Vector2i] = []
var _placement_counts: Dictionary = {}  ## { block_id: int }
var _budget_counts: Dictionary = {}  ## { budget_index: int }
var _relaxed_constraints: Dictionary = {}  ## { constraint_name: true }
var _block_registry: BlockBuilderRegistry


## ── Public API ───────────────────────────────────────────────────────────────

func build(level_data: GridLevelData, parent: Node3D) -> GridBuildResult:
	var result := GridBuildResult.new()
	_rules = level_data.level_rules
	_catalog = level_data.block_catalog
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_relaxed_constraints.clear()
	_block_registry = BlockBuilderRegistry.new()

	var attempt := 0
	var solved := false

	while attempt < _rules.max_retries and not solved:
		attempt += 1
		_init_grid()
		_stamp_zone_constraints()

		if not _place_anchors():
			result.warnings.append("Attempt %d: failed to place all anchors" % attempt)
			_relax_next_constraint()
			continue

		_generate_sightline_lanes()

		if not _fill_remaining_cells():
			result.warnings.append("Attempt %d: failed to fill all cells" % attempt)
			_relax_next_constraint()
			continue

		_enforce_budgets()
		solved = true

	if not solved:
		result.warnings.append("Solver exhausted retries — filling gaps with EMPTY/GROUND")
		_fill_empty_gaps()
		result.success = false

	_instantiate_scenes(parent, result, level_data)
	return result


## ── Step 1: Initialize grid ──────────────────────────────────────────────────

func _init_grid() -> void:
	_grid.clear()
	_anchor_positions.clear()
	_placement_counts.clear()
	_budget_counts.clear()

	for x in range(_rules.grid_width):
		var column: Array[GridCell] = []
		for z in range(_rules.grid_depth):
			var cell := GridCell.new()
			cell.coord = Vector2i(x, z)
			column.append(cell)
		_grid.append(column)


func _get_cell(coord: Vector2i) -> GridCell:
	if coord.x < 0 or coord.x >= _rules.grid_width:
		return null
	if coord.y < 0 or coord.y >= _rules.grid_depth:
		return null
	return _grid[coord.x][coord.y]


## ── Step 2: Stamp zone constraints ───────────────────────────────────────────

func _stamp_zone_constraints() -> void:
	for rule: ZoneRule in _rules.zone_rules:
		var cells := rule.get_cells(_rules.grid_width, _rules.grid_depth)
		for coord in cells:
			var cell := _get_cell(coord)
			if not cell:
				continue
			if rule.is_soft and "zone" not in _relaxed_constraints:
				# Store as soft constraints
				if not rule.allowed_heights.is_empty():
					if cell.soft_allowed_heights.is_empty():
						cell.soft_allowed_heights = rule.allowed_heights.duplicate()
					else:
						cell.soft_allowed_heights = _intersect_heights(
							cell.soft_allowed_heights, rule.allowed_heights)
				if not rule.allowed_types.is_empty():
					if cell.soft_allowed_types.is_empty():
						cell.soft_allowed_types = rule.allowed_types.duplicate()
					else:
						cell.soft_allowed_types = _intersect_types(
							cell.soft_allowed_types, rule.allowed_types)
			else:
				# Hard constraints
				if not rule.allowed_heights.is_empty():
					if cell.allowed_heights.is_empty():
						cell.allowed_heights = rule.allowed_heights.duplicate()
					else:
						cell.allowed_heights = _intersect_heights(
							cell.allowed_heights, rule.allowed_heights)
				if not rule.allowed_types.is_empty():
					if cell.allowed_types.is_empty():
						cell.allowed_types = rule.allowed_types.duplicate()
					else:
						cell.allowed_types = _intersect_types(
							cell.allowed_types, rule.allowed_types)
			for tag in rule.forbidden_tags:
				if tag not in cell.forbidden_tags:
					cell.forbidden_tags.append(tag)


## ── Step 3: Place anchors ────────────────────────────────────────────────────

func _place_anchors() -> bool:
	for anchor: AnchorPlacement in _rules.anchor_placements:
		var valid_cells := _get_anchor_valid_cells(anchor)
		if valid_cells.is_empty():
			if anchor.required:
				return false
			continue

		# Shuffle and pick first valid
		_shuffle_array(valid_cells)
		var placed := false

		for coord: Vector2i in valid_cells:
			var block := _resolve_anchor_block(anchor)
			if not block:
				break
			if _can_place_block(coord, block):
				_place_block(coord, block)
				_get_cell(coord).locked = true
				_anchor_positions.append(coord)

				# Apply facing
				# (stored on cell for instantiation phase — rotation applied later)

				placed = true
				break

		if not placed and anchor.required:
			return false

	return true


func _get_anchor_valid_cells(anchor: AnchorPlacement) -> Array[Vector2i]:
	# Get all cells in the anchor's allowed zone
	var zone := ZoneRule.new()
	zone.shape = anchor.zone_shape
	zone.ring_index = anchor.zone_ring_index
	zone.rect = anchor.zone_rect
	zone.index = anchor.zone_index
	var zone_cells := zone.get_cells(_rules.grid_width, _rules.grid_depth)

	# Filter by min_distance to existing anchors + not occupied
	var valid: Array[Vector2i] = []
	for coord in zone_cells:
		var cell := _get_cell(coord)
		if not cell or cell.is_occupied():
			continue

		var too_close := false
		for existing_anchor in _anchor_positions:
			var dist := maxi(
				absi(coord.x - existing_anchor.x),
				absi(coord.y - existing_anchor.y)
			)
			if dist < anchor.min_distance_to_anchors:
				too_close = true
				break

		if not too_close:
			valid.append(coord)

	return valid


func _resolve_anchor_block(anchor: AnchorPlacement) -> BlockDef:
	if anchor.block_id != "":
		return _catalog.get_by_id(anchor.block_id)
	# Pick from catalog matching the type filter
	var candidates: Array[BlockDef] = _catalog.get_blocks_by_type(anchor.block_type_filter)
	if candidates.is_empty():
		return null
	return BlockCatalog.pick_weighted_from(_rng, candidates)


## ── Step 4: Generate sightline lanes from anchors ────────────────────────────

func _generate_sightline_lanes() -> void:
	for anchor_coord in _anchor_positions:
		var anchor_cell := _get_cell(anchor_coord)
		if not anchor_cell or not anchor_cell.block_def:
			continue
		if anchor_cell.block_def.block_type != BlockDef.BlockType.SNIPER_NEST:
			continue

		# Mark the anchor's row and column as sightline-restricted
		for x in range(_rules.grid_width):
			var cell := _get_cell(Vector2i(x, anchor_coord.y))
			if cell and not cell.locked:
				cell.sightline_restricted = true

		for z in range(_rules.grid_depth):
			var cell := _get_cell(Vector2i(anchor_coord.x, z))
			if cell and not cell.locked:
				cell.sightline_restricted = true


## ── Step 5: Fill remaining cells ─────────────────────────────────────────────

func _fill_remaining_cells() -> bool:
	# Collect all unoccupied cells
	var open_cells: Array[Vector2i] = []
	for x in range(_rules.grid_width):
		for z in range(_rules.grid_depth):
			if not _get_cell(Vector2i(x, z)).is_occupied():
				open_cells.append(Vector2i(x, z))

	# Sort by most-constrained-first (smallest domain), with random tiebreak
	# We'll use a simple iterative approach: pick the most constrained each round
	while not open_cells.is_empty():
		# Find cell with smallest valid block set
		var best_idx := -1
		var best_count := 999999
		var best_candidates: Array[BlockDef] = []

		for i in range(open_cells.size()):
			var candidates := _get_valid_blocks(open_cells[i])
			if candidates.size() < best_count:
				best_count = candidates.size()
				best_idx = i
				best_candidates = candidates

		if best_idx == -1 or best_candidates.is_empty():
			return false  # Stuck — no valid blocks for some cell

		var coord := open_cells[best_idx]
		var block := BlockCatalog.pick_weighted_from(_rng, best_candidates)
		_place_block(coord, block)
		open_cells.remove_at(best_idx)

	return true


func _get_valid_blocks(coord: Vector2i) -> Array[BlockDef]:
	var cell := _get_cell(coord)
	if not cell:
		return []

	var candidates: Array[BlockDef] = []

	for block: BlockDef in _catalog.blocks:
		if not _block_fits_cell(coord, cell, block):
			continue
		candidates.append(block)

	return candidates


func _block_fits_cell(coord: Vector2i, cell: GridCell, block: BlockDef) -> bool:
	# Multi-cell blocks: check all cells they'd occupy
	if block.grid_size.x > 1 or block.grid_size.y > 1:
		for dx in range(block.grid_size.x):
			for dz in range(block.grid_size.y):
				var sub := _get_cell(coord + Vector2i(dx, dz))
				if not sub or sub.is_occupied():
					return false
				if not _single_cell_accepts(sub, block):
					return false
		# Check neighbor rules for all edge cells
		return _check_neighbor_rules_multi(coord, block)

	return _single_cell_accepts(cell, block) and _check_neighbor_rules(coord, block)


func _single_cell_accepts(cell: GridCell, block: BlockDef) -> bool:
	# Hard height constraint
	if not cell.allowed_heights.is_empty():
		if block.height_type not in cell.allowed_heights:
			return false

	# Hard type constraint
	if not cell.allowed_types.is_empty():
		if block.block_type not in cell.allowed_types:
			return false

	# Soft constraints (if not relaxed)
	if "zone" not in _relaxed_constraints:
		if not cell.soft_allowed_heights.is_empty():
			if block.height_type not in cell.soft_allowed_heights:
				return false
		if not cell.soft_allowed_types.is_empty():
			if block.block_type not in cell.soft_allowed_types:
				return false

	# Forbidden tags
	for tag in cell.forbidden_tags:
		if tag in block.tags:
			return false

	# Sightline restriction
	if cell.sightline_restricted:
		if block.height_type > _rules.sightline_max_height:
			return false

	# Max per level
	if block.max_per_level >= 0:
		var count: int = _placement_counts.get(block.id, 0)
		if count >= block.max_per_level:
			return false

	# Budget max constraints
	if "budget_max" not in _relaxed_constraints:
		for i in range(_rules.block_budgets.size()):
			var budget: BlockBudget = _rules.block_budgets[i]
			if budget.max_count >= 0 and budget.matches(block):
				var count: int = _budget_counts.get(i, 0)
				if count >= budget.max_count:
					return false

	return true


func _check_neighbor_rules(coord: Vector2i, block: BlockDef) -> bool:
	if "height_neighbor" in _relaxed_constraints:
		return true

	for rule: HeightNeighborRule in _rules.height_neighbor_rules:
		if rule.is_soft and "height_neighbor" in _relaxed_constraints:
			continue

		# Check: if this block is the source, are neighbors forbidden?
		if block.height_type == rule.source_height:
			for offset in NEIGHBORS:
				var neighbor := _get_cell(coord + offset)
				if neighbor and neighbor.block_def:
					if neighbor.block_def.height_type in rule.forbidden_neighbor_heights:
						return false

		# Check reverse: if a neighbor is the source, is this block forbidden?
		for offset in NEIGHBORS:
			var neighbor := _get_cell(coord + offset)
			if neighbor and neighbor.block_def:
				if neighbor.block_def.height_type == rule.source_height:
					if block.height_type in rule.forbidden_neighbor_heights:
						return false

	return true


func _check_neighbor_rules_multi(coord: Vector2i, block: BlockDef) -> bool:
	# Collect all edge neighbor cells for the multi-cell footprint
	for dx in range(block.grid_size.x):
		for dz in range(block.grid_size.y):
			if not _check_neighbor_rules(coord + Vector2i(dx, dz), block):
				return false
	return true


## ── Step 6: Enforce budgets ──────────────────────────────────────────────────

func _enforce_budgets() -> void:
	for i in range(_rules.block_budgets.size()):
		var budget: BlockBudget = _rules.block_budgets[i]
		if budget.min_count <= 0:
			continue

		var count: int = _budget_counts.get(i, 0)
		if count >= budget.min_count:
			continue

		# Need more blocks of this type — swap unlocked low-priority cells
		var deficit := budget.min_count - count
		var swappable := _get_swappable_cells(budget)

		for j in range(mini(deficit, swappable.size())):
			var coord: Vector2i = swappable[j]
			var candidates := _get_budget_candidates(coord, budget)
			if not candidates.is_empty():
				var old_block := _get_cell(coord).block_def
				var new_block := BlockCatalog.pick_weighted_from(_rng, candidates)
				_unplace_block(coord, old_block)
				_place_block(coord, new_block)


func _get_swappable_cells(budget: BlockBudget) -> Array[Vector2i]:
	## Find unlocked cells that DON'T match the budget (candidates for replacement).
	var cells: Array[Vector2i] = []
	for x in range(_rules.grid_width):
		for z in range(_rules.grid_depth):
			var cell := _get_cell(Vector2i(x, z))
			if cell.locked or not cell.is_occupied():
				continue
			if not budget.matches(cell.block_def):
				cells.append(cell.coord)
	# Sort by weight descending (replace high-weight/common blocks first)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _get_cell(a).block_def.weight > _get_cell(b).block_def.weight
	)
	return cells


func _get_budget_candidates(coord: Vector2i, budget: BlockBudget) -> Array[BlockDef]:
	var cell := _get_cell(coord)
	var candidates: Array[BlockDef] = []
	for block: BlockDef in _catalog.blocks:
		if not budget.matches(block):
			continue
		if _block_fits_cell(coord, cell, block):
			candidates.append(block)
	return candidates


## ── Placement helpers ────────────────────────────────────────────────────────

func _place_block(coord: Vector2i, block: BlockDef) -> void:
	for dx in range(block.grid_size.x):
		for dz in range(block.grid_size.y):
			var cell := _get_cell(coord + Vector2i(dx, dz))
			if cell:
				cell.block_def = block

	_placement_counts[block.id] = _placement_counts.get(block.id, 0) + 1

	for i in range(_rules.block_budgets.size()):
		if _rules.block_budgets[i].matches(block):
			_budget_counts[i] = _budget_counts.get(i, 0) + 1


func _unplace_block(coord: Vector2i, block: BlockDef) -> void:
	for dx in range(block.grid_size.x):
		for dz in range(block.grid_size.y):
			var cell := _get_cell(coord + Vector2i(dx, dz))
			if cell:
				cell.block_def = null

	_placement_counts[block.id] = maxi(_placement_counts.get(block.id, 0) - 1, 0)

	for i in range(_rules.block_budgets.size()):
		if _rules.block_budgets[i].matches(block):
			_budget_counts[i] = maxi(_budget_counts.get(i, 0) - 1, 0)


func _can_place_block(coord: Vector2i, block: BlockDef) -> bool:
	for dx in range(block.grid_size.x):
		for dz in range(block.grid_size.y):
			var cell := _get_cell(coord + Vector2i(dx, dz))
			if not cell or cell.is_occupied():
				return false
	return true


## ── Gap filler (fallback) ────────────────────────────────────────────────────

func _fill_empty_gaps() -> void:
	# Find any GROUND/EMPTY block in the catalog as fallback
	var fallback: BlockDef = null
	for block in _catalog.blocks:
		if block.height_type == BlockDef.HeightType.GROUND:
			fallback = block
			break

	if not fallback:
		return

	for x in range(_rules.grid_width):
		for z in range(_rules.grid_depth):
			var cell := _get_cell(Vector2i(x, z))
			if not cell.is_occupied():
				_place_block(Vector2i(x, z), fallback)


## ── Constraint relaxation ────────────────────────────────────────────────────

func _relax_next_constraint() -> void:
	for constraint_name in _rules.soft_constraint_relaxation_order:
		if constraint_name not in _relaxed_constraints:
			_relaxed_constraints[constraint_name] = true
			return


## ── Scene instantiation ──────────────────────────────────────────────────────

func _instantiate_scenes(
	parent: Node3D,
	result: GridBuildResult,
	level_data: GridLevelData,
) -> void:
	# Build result grid
	result.grid.resize(_rules.grid_width)
	for x in range(_rules.grid_width):
		result.grid[x] = []
		result.grid[x].resize(_rules.grid_depth)

	# Track which multi-cell blocks we've already instantiated
	var instantiated_origins: Dictionary = {}  ## { "x,z": true }

	# Container node for all blocks
	var blocks_root := Node3D.new()
	blocks_root.name = "GridBlocks"
	parent.add_child(blocks_root)

	for x in range(_rules.grid_width):
		for z in range(_rules.grid_depth):
			var cell := _get_cell(Vector2i(x, z))
			if not cell.is_occupied():
				continue

			var block := cell.block_def

			# For multi-cell blocks, only instantiate at the origin cell
			if block.grid_size.x > 1 or block.grid_size.y > 1:
				var origin_key := _find_block_origin(Vector2i(x, z), block)
				var key := "%d,%d" % [origin_key.x, origin_key.y]
				if key in instantiated_origins:
					continue
				instantiated_origins[key] = true

			# Create the block instance — either from scene or code builder
			var instance: Node3D
			if block.block_scene:
				instance = block.block_scene.instantiate()
			elif _block_registry.has_builder(block.id):
				instance = Node3D.new()
				blocks_root.add_child(instance)  # Must be in tree before building
				_block_registry.build_block(block.id, instance, _rng)
			else:
				continue  # No scene and no builder — skip

			instance.name = "%s_%d_%d" % [block.id, x, z]
			instance.position = Vector3(
				x * _rules.cell_size,
				0.0,
				z * _rules.cell_size,
			)

			if not instance.is_inside_tree():
				blocks_root.add_child(instance)
			result.instances.append(instance)
			result.grid[x][z] = { "block_def": block, "instance": instance }

			# Collect spawn and activity points
			_collect_markers(instance, result)

	# Ground plane
	_create_ground_plane(blocks_root, level_data)


func _find_block_origin(coord: Vector2i, block: BlockDef) -> Vector2i:
	## For a multi-cell block, find the top-left origin cell.
	## Walk backwards until the cell doesn't have this block.
	var origin := coord
	while origin.x > 0:
		var left := _get_cell(origin + Vector2i(-1, 0))
		if left and left.block_def == block:
			origin.x -= 1
		else:
			break
	while origin.y > 0:
		var up := _get_cell(origin + Vector2i(0, -1))
		if up and up.block_def == block:
			origin.y -= 1
		else:
			break
	return origin


func _collect_markers(instance: Node3D, result: GridBuildResult) -> void:
	# Recursively find SpawnPoint and ActivityPoint markers
	var stack: Array[Node] = [instance]
	while not stack.is_empty():
		var node := stack.pop_back()
		# Check by class name since we don't want to import the class here
		if node.is_in_group("spawn_point") or node.get_class() == "Marker3D":
			if node.has_meta("spawn_type"):
				result.spawn_points.append(node)
		if node.is_in_group("activity_point"):
			result.activity_points.append(node)
		for child in node.get_children():
			stack.append(child)


func _create_ground_plane(parent: Node3D, level_data: GridLevelData) -> void:
	var total_width: float = _rules.grid_width * _rules.cell_size
	var total_depth: float = _rules.grid_depth * _rules.cell_size

	var mesh := PlaneMesh.new()
	mesh.size = Vector2(total_width, total_depth)

	var ground := StaticBody3D.new()
	ground.name = "GroundPlane"

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	if level_data.ground_material:
		mesh_inst.material_override = level_data.ground_material

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(total_width, 0.1, total_depth)
	collision.shape = shape
	collision.position.y = -0.05

	ground.add_child(mesh_inst)
	ground.add_child(collision)

	# Center the ground under the grid
	ground.position = Vector3(
		total_width / 2.0 - _rules.cell_size / 2.0,
		0.0,
		total_depth / 2.0 - _rules.cell_size / 2.0,
	)

	parent.add_child(ground)


## ── Utility ──────────────────────────────────────────────────────────────────

func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _intersect_heights(
	a: Array[BlockDef.HeightType],
	b: Array[BlockDef.HeightType],
) -> Array[BlockDef.HeightType]:
	var result: Array[BlockDef.HeightType] = []
	for h in a:
		if h in b:
			result.append(h)
	return result


static func _intersect_types(
	a: Array[BlockDef.BlockType],
	b: Array[BlockDef.BlockType],
) -> Array[BlockDef.BlockType]:
	var result: Array[BlockDef.BlockType] = []
	for t in a:
		if t in b:
			result.append(t)
	return result
