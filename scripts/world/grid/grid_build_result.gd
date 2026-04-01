class_name GridBuildResult
extends RefCounted
## Output of GridLevelBuilder.build(). Contains the placed block instances,
## the final grid map, and aggregated spawn/activity points.

var success: bool = true
var warnings: PackedStringArray = []

## The final grid — 2D array indexed [x][z], each entry is a Dictionary:
## { "block_def": BlockDef, "instance": Node3D } or null for empty
var grid: Array = []

## All block Node3D instances (already positioned, ready to add to tree)
var instances: Array[Node3D] = []

## Aggregated markers from all block instances
var spawn_points: Array[Node3D] = []
var activity_points: Array[Node3D] = []

## Blocks chosen for player spawn and extraction zones
## (the level script reads these to place SpawnPoint / ExtractionZone nodes)
var player_spawn_block: Node3D = null  ## The instance chosen for player spawn
var player_spawn_cell: Vector2i = Vector2i(-1, -1)
var extraction_blocks: Array[Node3D] = []  ## Instances chosen for extraction
var extraction_cells: Array[Vector2i] = []
