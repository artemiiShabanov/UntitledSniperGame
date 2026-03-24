class_name NpcTechnician
extends NpcBase
## Technician — equipment/machinery NPC.
## Activity cycle: operate → inspect → rest.

func _ready() -> void:
	if not npc_type:
		npc_type = preload("res://data/npcs/technician.tres")
	super._ready()
