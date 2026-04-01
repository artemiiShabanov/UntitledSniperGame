class_name BlockBudget
extends Resource
## Min/max count constraint for blocks matching a filter.
## Used to ensure the level has enough enemy blocks, not too many tall blocks, etc.

enum FilterBy { HEIGHT_TYPE, BLOCK_TYPE, TAG }

@export var filter_by: FilterBy = FilterBy.BLOCK_TYPE
@export var filter_value: String = ""  ## e.g. "TALL", "ENEMY", "warehouse"

@export_group("Counts")
@export var min_count: int = 0  ## Minimum required (checked post-fill, repaired if needed)
@export var max_count: int = -1  ## Maximum allowed during fill (-1 = unlimited)

## Soft constraints can be relaxed by the solver if it gets stuck
@export var is_soft: bool = false


## ── Helpers ──────────────────────────────────────────────────────────────────

## Check if a BlockDef matches this budget's filter.
func matches(block: BlockDef) -> bool:
	match filter_by:
		FilterBy.HEIGHT_TYPE:
			return BlockDef.HeightType.keys()[block.height_type] == filter_value
		FilterBy.BLOCK_TYPE:
			return BlockDef.BlockType.keys()[block.block_type] == filter_value
		FilterBy.TAG:
			return filter_value in block.tags
	return false
