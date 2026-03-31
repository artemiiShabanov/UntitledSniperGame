extends Label
## Displays weapon state: action, ammo type, magazine/reserve, and run credits.
## Also manages a lazily-created ammo icon next to the label.

var _ammo_icon_rect: TextureRect = null


func _ready() -> void:
	var bold_font: Font = PaletteTheme.bold_font
	if bold_font:
		add_theme_font_override("font", bold_font)


func update(wpn: Node3D) -> void:
	const STATE_NAMES := ["IDLE", "AIMING", "BOLT_CYCLING", "RELOADING", "INSPECTING"]
	var ammo: AmmoType = wpn.get_current_ammo_type()
	var ammo_name := ammo.ammo_name if ammo else "???"
	var state_idx: int = clampi(wpn.state, 0, STATE_NAMES.size() - 1)
	text = "%s | %s %d/%d | $%d" % [
		STATE_NAMES[state_idx],
		ammo_name,
		wpn.ammo_in_magazine,
		wpn.ammo_reserve,
		RunManager.get_run_credits(),
	]
	# Color the label to match ammo type
	if ammo:
		add_theme_color_override("font_color", ammo.tracer_color)
	else:
		remove_theme_color_override("font_color")
	_update_ammo_icon(ammo)


func _update_ammo_icon(ammo: AmmoType) -> void:
	if not ammo or not ammo.icon:
		if _ammo_icon_rect:
			_ammo_icon_rect.visible = false
		return
	if not _ammo_icon_rect:
		_ammo_icon_rect = TextureRect.new()
		_ammo_icon_rect.custom_minimum_size = Vector2(28, 28)
		_ammo_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ammo_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Position next to weapon state label (top-right)
		_ammo_icon_rect.anchors_preset = Control.PRESET_TOP_RIGHT
		_ammo_icon_rect.anchor_left = 1.0
		_ammo_icon_rect.anchor_right = 1.0
		_ammo_icon_rect.offset_left = -530.0
		_ammo_icon_rect.offset_top = 25.0
		_ammo_icon_rect.offset_right = -502.0
		_ammo_icon_rect.offset_bottom = 53.0
		get_parent().add_child(_ammo_icon_rect)
	_ammo_icon_rect.texture = ammo.icon
	_ammo_icon_rect.visible = true
