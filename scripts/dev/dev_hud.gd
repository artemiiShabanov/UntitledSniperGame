extends CanvasLayer
## Debug HUD overlay — shows real-time game state. Toggle with F3.

var _label: Label
var _visible: bool = false


func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.name = "DevHUDLabel"
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.offset_left = 10
	_label.offset_bottom = -10
	_label.offset_top = -250
	_label.offset_right = 350
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_visible = not _visible
		visible = _visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _visible:
		return

	var lines: PackedStringArray = []
	lines.append("=== DEV HUD ===")
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("State: %s" % RunManager.GameState.keys()[RunManager.game_state])
	lines.append("Phase: %d / %d" % [RunManager.threat_phase, RunManager.THREAT_PHASE_MAX])
	lines.append("Elapsed: %.0fs" % RunManager.run_elapsed)
	lines.append("Castle HP: %d / %d" % [RunManager.castle_hp, RunManager.castle_max_hp])
	lines.append("Lives: %d / %d" % [RunManager.lives, RunManager.max_lives])
	lines.append("Score: %d  XP: %d" % [RunManager.run_score, RunManager.run_xp])

	# Extraction window.
	if RunManager.extraction_window_open:
		lines.append("Extraction: OPEN (%.0fs)" % RunManager.extraction_window_timer)
	else:
		lines.append("Extraction: closed")

	# Warrior counts.
	var friendly := get_tree().get_nodes_in_group("warrior_friendly").size()
	var hostile := get_tree().get_nodes_in_group("warrior_hostile").size()
	lines.append("Warriors: %d friendly / %d hostile" % [friendly, hostile])

	# Active opportunity.
	var runners := get_tree().get_nodes_in_group("opportunity_runner")
	if not runners.is_empty():
		var runner: OpportunityRunner = runners[0]
		var opp := runner.get_active_opportunity()
		if opp:
			lines.append("Opportunity: %s %s (%.0fs)" % [opp.name, runner.get_active_progress(), runner.get_active_time_remaining()])
		else:
			lines.append("Opportunity: none")

	_label.text = "\n".join(lines)
