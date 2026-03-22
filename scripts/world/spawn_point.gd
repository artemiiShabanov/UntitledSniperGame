class_name SpawnPoint
extends Marker3D
## Marks a spawn location in a level. Use groups or the spawn_type export
## to query specific kinds at runtime.

enum Type { PLAYER, ENEMY, EXTRACTION }

@export var spawn_type: Type = Type.PLAYER
@export var spawn_group: String = ""  ## Grouping tag (e.g., "rooftop", "ground")
@export var facing_direction: float = 0.0  ## Y rotation in degrees for spawned entity
@export var behavior_tag: String = "default"  ## "idle", "scanning", "patrol_a", etc.
