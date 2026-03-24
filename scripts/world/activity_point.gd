class_name ActivityPoint
extends Marker3D
## Marks a location where NPCs perform activities.
## Place in levels like SpawnPoints. NPCs navigate between matching points.

enum Activity { WORK, CARRY, OPERATE, INSPECT, WALK, EAT, REST, IDLE }

@export var activity: Activity = Activity.WORK
@export var facing_direction: float = 0.0  ## Y rotation in degrees for NPC while performing
@export var point_group: String = ""  ## Optional tag for linking related points (e.g., "warehouse_a")

## Maps activity enum values to the string keys used in NpcType.activity_durations.
const ACTIVITY_NAMES: Dictionary = {
	Activity.WORK: "work",
	Activity.CARRY: "carry",
	Activity.OPERATE: "operate",
	Activity.INSPECT: "inspect",
	Activity.WALK: "walk",
	Activity.EAT: "eat",
	Activity.REST: "rest",
	Activity.IDLE: "idle",
}


func get_activity_name() -> String:
	return ACTIVITY_NAMES.get(activity, "idle")
