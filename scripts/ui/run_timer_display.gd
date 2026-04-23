extends Label
## Displays current phase number and elapsed time.

func _ready() -> void:
	visible = false
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)
	_apply_palette()
	RunManager.threat_phase_changed.connect(_on_phase_changed)
	RunManager.run_completed.connect(func(_s: bool) -> void: visible = false)
	RunManager.run_started.connect(func() -> void: visible = true; _refresh())
	PaletteManager.palette_changed.connect(_on_palette_changed)


func _process(_delta: float) -> void:
	if visible and RunManager.game_state == RunManager.GameState.IN_RUN:
		_refresh()


func _refresh() -> void:
	text = "PHASE %d | %s" % [RunManager.threat_phase, FormatUtils.format_time(RunManager.get_run_time_elapsed())]


func _apply_palette() -> void:
	add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_GOOD_MUTED))


func _on_palette_changed(_palette: PaletteResource) -> void:
	_apply_palette()


func _on_phase_changed(_phase: int) -> void:
	_refresh()
