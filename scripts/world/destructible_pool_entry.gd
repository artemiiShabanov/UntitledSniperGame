class_name DestructiblePoolEntry
extends Resource
## A single entry in a destructible target pool. Mirrors EnemyPoolEntry/NpcPoolEntry.

## Whether this is a static (placed at spawn points) or dynamic (spawned at random positions) type.
enum SpawnMode { STATIC, DYNAMIC }

@export var scene: PackedScene
@export var weight: float = 1.0
@export var max_per_run: int = -1  ## -1 = unlimited
@export var spawn_mode: SpawnMode = SpawnMode.STATIC
