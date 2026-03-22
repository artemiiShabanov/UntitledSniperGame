class_name LevelEventData
extends Resource
## Defines a level event that can trigger during a run.

@export var event_name: String = ""
@export var trigger_time_range: Vector2 = Vector2(60.0, 180.0)  ## Seconds into run
@export var probability: float = 0.5  ## Chance this event is selected (0-1)
@export var event_script: GDScript  ## Must have execute(level, params) function
@export var params: Dictionary = {}
