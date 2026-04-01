class_name AnchorPlacement
extends Resource
## Defines where an important block (sniper nest, event trigger) can be placed.
## Instead of a fixed cell, the anchor specifies a zone it may land in,
## so placement varies between runs while staying in designer-intended regions.

enum FacingMode { FIXED, INWARD, RANDOM }

## What to place — specific block ID, or any block matching type filter
@export var block_id: String = ""  ## If set, use this exact block from catalog
@export var block_type_filter: BlockDef.BlockType = BlockDef.BlockType.SNIPER_NEST

## Where it can go — zone shape + region
@export_group("Zone")
@export var zone_shape: ZoneRule.ZoneShape = ZoneRule.ZoneShape.RING
@export var zone_ring_index: int = 0  ## For RING shape: 0 = outermost
@export var zone_rect: Rect2i = Rect2i()  ## For RECT shape
@export var zone_index: int = 0  ## For ROW/COLUMN shape

## Spacing
@export_group("Spacing")
@export var min_distance_to_anchors: int = 4  ## Minimum Chebyshev distance to other anchors

## Facing
@export_group("Facing")
@export var facing_mode: FacingMode = FacingMode.INWARD
@export var facing_angle: float = 0.0  ## Used when facing_mode == FIXED (Y rotation degrees)

## Priority
@export_group("Priority")
@export var required: bool = true  ## Hard constraint — fail build if can't place
