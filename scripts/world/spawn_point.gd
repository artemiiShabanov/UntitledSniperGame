class_name SpawnPoint
extends Marker3D
## Marks a spawn location in a level. Use groups or the spawn_type export
## to query specific kinds at runtime.

enum Type { PLAYER, ENEMY, EXTRACTION }

@export var spawn_type: Type = Type.PLAYER
