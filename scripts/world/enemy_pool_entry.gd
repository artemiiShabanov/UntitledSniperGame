class_name EnemyPoolEntry
extends Resource

@export var enemy_scene: PackedScene
@export var weight: float = 1.0
@export var max_per_run: int = -1  ## -1 = unlimited
@export var min_phase: int = 1  ## Minimum threat phase (1-10) before this enemy can spawn
