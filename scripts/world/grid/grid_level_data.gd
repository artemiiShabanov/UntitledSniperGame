class_name GridLevelData
extends LevelData
## Extends LevelData with grid generation fields.
## Assign a BlockCatalog and GridLevelRules to enable procedural layout.
## BaseLevel checks for this type and calls GridLevelBuilder automatically.

@export_group("Grid Generation")
@export var block_catalog: BlockCatalog
@export var level_rules: GridLevelRules
@export var ground_material: StandardMaterial3D  ## Optional themed ground plane material
