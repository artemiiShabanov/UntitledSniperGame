class_name NpcType
extends Resource
## Defines properties for a neutral NPC type.
## Saved as .tres files in res://data/npcs/.

enum Kind { LABORER, TECHNICIAN, CIVILIAN }

@export var npc_name: String = ""
@export var npc_id: String = ""
@export var kind: Kind = Kind.LABORER

@export_group("Behavior")
@export var activity_durations: Dictionary = {}  ## { "work": 10.0, "carry": 8.0, "rest": 6.0 }
@export var move_speed: float = 1.2
@export var panic_flee_speed: float = 3.5
@export var panic_duration: float = 6.0  ## Seconds spent fleeing before calming down
@export var panic_threshold: float = 0.3  ## loudness/distance ratio to trigger panic

@export_group("Penalty")
@export var kill_penalty: int = 100  ## Credits deducted from run earnings

@export_group("Visuals")
@export var mesh_color: Color = Color(0.2, 0.6, 0.9)  ## Distinct from enemy mesh


## Returns the ordered activity list for this NPC's kind.
func get_activity_list() -> PackedStringArray:
	match kind:
		Kind.LABORER:
			return PackedStringArray(["work", "carry", "rest"])
		Kind.TECHNICIAN:
			return PackedStringArray(["operate", "inspect", "rest"])
		Kind.CIVILIAN:
			return PackedStringArray(["walk", "eat", "idle"])
	return PackedStringArray([])
