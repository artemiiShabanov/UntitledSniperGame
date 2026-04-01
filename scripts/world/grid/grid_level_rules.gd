class_name GridLevelRules
extends Resource
## All per-level constraints for grid-based level generation.
## Rules are pure data — the solver reads them, designers edit them.

## ── Grid dimensions ──────────────────────────────────────────────────────────

@export var grid_width: int = 15
@export var grid_depth: int = 15
@export var cell_size: float = 15.0  ## Meters per cell side

## ── Anchors ──────────────────────────────────────────────────────────────────

@export_group("Anchors")
@export var anchor_placements: Array[AnchorPlacement] = []

## ── Zone constraints ─────────────────────────────────────────────────────────

@export_group("Zone Rules")
@export var zone_rules: Array[ZoneRule] = []

## ── Height adjacency ─────────────────────────────────────────────────────────

@export_group("Height Neighbor Rules")
@export var height_neighbor_rules: Array[HeightNeighborRule] = []

## ── Sightline config ─────────────────────────────────────────────────────────
## Sightline lanes are auto-generated from sniper nest anchors.
## The row and column of each placed nest are height-capped.

@export_group("Sightlines")
@export var sightline_max_height: BlockDef.HeightType = BlockDef.HeightType.LOW

## ── Block budgets ────────────────────────────────────────────────────────────

@export_group("Block Budget")
@export var block_budgets: Array[BlockBudget] = []

## ── Solver config ────────────────────────────────────────────────────────────

@export_group("Solver")
@export var max_retries: int = 5
## Order in which soft constraints are relaxed when solver gets stuck.
## Values: "zone", "height_neighbor", "budget_max"
@export var soft_constraint_relaxation_order: PackedStringArray = [
	"height_neighbor", "budget_max", "zone"
]
