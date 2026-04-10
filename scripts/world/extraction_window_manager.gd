class_name ExtractionWindowManager
extends Node
## Manages extraction windows during a run.
## Listens to RunManager signals. When a window opens, activates one random
## extraction zone in the level. Deactivates it when the window closes.

var _zones: Array[ExtractionZone] = []
var _active_zone: ExtractionZone = null


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)
	RunManager.extraction_window_opened.connect(_on_window_opened)
	RunManager.extraction_window_closed.connect(_on_window_closed)
	RunManager.run_completed.connect(func(_s: bool) -> void: _deactivate_all())


func _on_run_started() -> void:
	_zones.clear()
	for node in get_tree().get_nodes_in_group("extraction_zone"):
		if node is ExtractionZone:
			_zones.append(node)
	_deactivate_all()


func _on_window_opened(duration: float) -> void:
	if _zones.is_empty():
		return

	# Pick a random zone to activate.
	_active_zone = _zones.pick_random()
	_active_zone.visible = true
	_active_zone.monitoring = true
	_active_zone.monitorable = true

	RunManager.announce_event("EXTRACTION OPEN — %.0fs" % duration)


func _on_window_closed() -> void:
	_deactivate_all()
	_active_zone = null
	RunManager.announce_event("EXTRACTION CLOSED")


func _deactivate_all() -> void:
	for zone in _zones:
		zone.visible = false
		zone.monitoring = false
		zone.monitorable = false
		zone.player_inside = false
