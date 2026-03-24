class_name NpcCivilian
extends NpcBase
## Civilian — general presence NPC.
## Activity cycle: walk → eat → idle.

func _ready() -> void:
	if not npc_type:
		npc_type = preload("res://data/npcs/civilian.tres")
	super._ready()
