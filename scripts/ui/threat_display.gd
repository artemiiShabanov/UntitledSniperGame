extends Label
## Displays current threat phase with color-coded severity.

func _ready() -> void:
	visible = false
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)
	RunManager.threat_phase_changed.connect(func(_p: RunManager.ThreatPhase) -> void: refresh())
	RunManager.run_started.connect(func() -> void: refresh())
	RunManager.run_completed.connect(func(_s: bool) -> void: visible = false)
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: refresh())


func refresh() -> void:
	var phase_name := RunManager.get_threat_phase_name()
	text = "THREAT: %s" % phase_name
	match RunManager.threat_phase:
		RunManager.ThreatPhase.EARLY:
			add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
		RunManager.ThreatPhase.MID:
			add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		RunManager.ThreatPhase.LATE:
			add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))
