class_name ZoneRule
extends Resource
## Region-based constraint: restricts which blocks can appear in a zone.
## Zones are defined by shape (ring, rect, row, column) and filter by
## allowed heights, allowed types, and forbidden tags.

enum ZoneShape { RING, RECT, ROW, COLUMN }

@export var shape: ZoneShape = ZoneShape.RING

## Shape parameters — only the relevant one is used based on shape
@export var ring_index: int = 0  ## 0 = outermost ring, 1 = next inner, etc.
@export var rect: Rect2i = Rect2i()  ## For RECT shape
@export var index: int = 0  ## For ROW or COLUMN shape

## Filters — empty array means "all allowed"
@export_group("Constraints")
@export var allowed_heights: Array[BlockDef.HeightType] = []
@export var allowed_types: Array[BlockDef.BlockType] = []
@export var forbidden_tags: PackedStringArray = []

## Soft constraints can be relaxed by the solver if it gets stuck
@export var is_soft: bool = false


## ── Helpers ──────────────────────────────────────────────────────────────────

## Returns all grid cells this zone covers, given grid dimensions.
func get_cells(grid_width: int, grid_depth: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match shape:
		ZoneShape.RING:
			for x in range(grid_width):
				for z in range(grid_depth):
					var dist_to_edge := mini(
						mini(x, grid_width - 1 - x),
						mini(z, grid_depth - 1 - z)
					)
					if dist_to_edge == ring_index:
						cells.append(Vector2i(x, z))
		ZoneShape.RECT:
			for x in range(rect.position.x, rect.end.x):
				for z in range(rect.position.y, rect.end.y):
					if x >= 0 and x < grid_width and z >= 0 and z < grid_depth:
						cells.append(Vector2i(x, z))
		ZoneShape.ROW:
			if index >= 0 and index < grid_depth:
				for x in range(grid_width):
					cells.append(Vector2i(x, index))
		ZoneShape.COLUMN:
			if index >= 0 and index < grid_width:
				for z in range(grid_depth):
					cells.append(Vector2i(index, z))
	return cells
