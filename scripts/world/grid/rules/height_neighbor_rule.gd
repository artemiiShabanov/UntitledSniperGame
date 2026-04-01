class_name HeightNeighborRule
extends Resource
## Adjacency constraint: blocks of a given height cannot neighbor
## blocks of certain other heights. Checked for all 4 cardinal neighbors.

## The height this rule applies to
@export var source_height: BlockDef.HeightType = BlockDef.HeightType.TALL

## Heights that cannot be adjacent to source_height
@export var forbidden_neighbor_heights: Array[BlockDef.HeightType] = []

## Soft constraints can be relaxed by the solver if it gets stuck
@export var is_soft: bool = false
