extends Label
## Shows the active opportunity name, countdown timer, and kill progress.
## Polls the OpportunityRunner node in the level scene tree each frame.

var _runner: OpportunityRunner = null


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)
	RunManager.run_completed.connect(func(_s: bool) -> void: _hide())
	visible = false


func _on_run_started() -> void:
	_runner = null
	visible = false


func _process(_delta: float) -> void:
	if RunManager.game_state != RunManager.GameState.IN_RUN:
		return

	# Lazy-find the runner in the scene tree via group.
	if _runner == null:
		var runners := get_tree().get_nodes_in_group("opportunity_runner")
		if not runners.is_empty():
			_runner = runners[0] as OpportunityRunner

	if _runner == null:
		visible = false
		return

	var opp := _runner.get_active_opportunity()
	if opp == null:
		visible = false
		return

	var time_left := _runner.get_active_time_remaining()
	var progress := _runner.get_active_progress()

	if opp.duration > 0.0:
		text = "%s  %s  %.0fs" % [opp.name.to_upper(), progress, time_left]
	else:
		text = "%s  %s" % [opp.name.to_upper(), progress]

	var accent := PaletteManager.get_color(PaletteManager.SLOT_REWARD)
	add_theme_color_override("font_color", accent)
	visible = true


func _hide() -> void:
	_runner = null
	visible = false
