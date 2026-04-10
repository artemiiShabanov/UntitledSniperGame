extends Label
## Displays weapon state: action, bullets remaining, and run score.

func _ready() -> void:
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)


func update(wpn: Node3D) -> void:
	const STATE_NAMES := ["IDLE", "AIMING", "BOLT_CYCLING"]
	var state_idx: int = clampi(wpn.state, 0, STATE_NAMES.size() - 1)
	text = "%s | %d ROUNDS | SCORE %d" % [
		STATE_NAMES[state_idx],
		wpn.bullets_remaining,
		RunManager.get_run_score(),
	]
