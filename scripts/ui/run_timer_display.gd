extends Label
## Displays run timer with color-coded urgency.

func _ready() -> void:
	visible = false
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)
	RunManager.run_timer_updated.connect(_on_timer_updated)
	RunManager.run_completed.connect(func(_s: bool) -> void: visible = false)


func _on_timer_updated(time_left: float) -> void:
	visible = RunManager.game_state == RunManager.GameState.IN_RUN or \
		RunManager.game_state == RunManager.GameState.EXTRACTING
	text = FormatUtils.format_time(time_left)
	if time_left <= 30.0:
		add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))
	else:
		add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
