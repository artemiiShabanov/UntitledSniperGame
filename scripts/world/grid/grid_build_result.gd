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
