extends Label
## Displays current threat phase (1-10) with color-coded severity.

func _ready() -> void:
	visible = false
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)
	RunManager.threat_phase_changed.connect(func(_p: int) -> void: refresh())
	RunManager.run_started.connect(func() -> void: refresh())
	RunManager.run_completed.connect(func(_s: bool) -> void: visible = false)
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: refresh())


func refresh() -> void:
	text = "THREAT: %s" % RunManager.get_threat_phase_name()
	var phase := RunManager.threat_phase
	var color: Color
	if phase <= 3:
		# Phases 1-3: friendly (green)
		color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
	elif phase <= 6:
		# Phases 4-6: warning (yellow/loot)
		color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
	else:
		# Phases 7-10: danger (red)
		color = PaletteManager.get_color(PaletteManager.SLOT_DANGER)
	add_theme_color_override("font_color", color)
