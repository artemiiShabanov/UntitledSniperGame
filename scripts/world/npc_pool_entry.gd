class_name NpcPoolEntry
extends Resource
## A single entry in an NPC pool. Mirrors EnemyPoolEntry.

@export var npc_scene: PackedScene
@export var weight: float = 1.0
@export var max_per_run: int = -1  ## -1 = unlimited
