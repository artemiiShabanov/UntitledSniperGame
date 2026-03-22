class_name LevelEventRunner
extends Node
## Triggers level events at scheduled times during a run.

var _events: Array[Dictionary] = []  ## [{data: LevelEventData, fire_time: float, fired: bool}]
var _level: BaseLevel


func setup(events: Array[LevelEventData], rng: RandomNumberGenerator, level: BaseLevel) -> void:
	_level = level
	for event_data in events:
		var fire_time := rng.randf_range(event_data.trigger_time_range.x, event_data.trigger_time_range.y)
		_events.append({
			"data": event_data,
			"fire_time": fire_time,
			"fired": false,
		})


func _process(_delta: float) -> void:
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	var elapsed := RunManager.get_run_time_elapsed()
	for event in _events:
		if event.fired:
			continue
		if elapsed >= event.fire_time:
			event.fired = true
			_execute_event(event.data)


func _execute_event(event_data: LevelEventData) -> void:
	if event_data.event_script == null:
		return
	var instance = event_data.event_script.new()
	if instance.has_method("execute"):
		instance.execute(_level, event_data.params)
