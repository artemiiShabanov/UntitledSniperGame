class_name NpcLaborer
extends NpcBase
## Laborer — heavy manual work NPC.
## Activity cycle: work → carry → rest.

func _ready() -> void:
	if not npc_type:
		npc_type = preload("res://data/npcs/laborer.tres")
	super._ready()
