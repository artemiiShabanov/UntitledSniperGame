extends Control
## Palette selection panel — view unlocked color palettes, preview and equip them.
## Locked palettes show their unlock condition.

signal panel_closed

@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _bold_font: Font = null
var _current_selection: StringName = &""


func _ready() -> void:
	close_btn.pressed.connect(func(): panel_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_bold_font = PaletteTheme.bold_font
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		if visible:
			_rebuild()
	)


func open() -> void:
	visible = true
	_current_selection = PaletteManager.current.palette_name
	_rebuild()


func _rebuild() -> void:
	UIUtils.clear_children(item_list)

	var title := Label.new()
	title.text = "COLOR PALETTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	if _bold_font:
		title.add_theme_font_override("font", _bold_font)
	title.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
	item_list.add_child(title)

	var sep := HSeparator.new()
	item_list.add_child(sep)

	var buttons: Array[Button] = []

	for palette: PaletteResource in PaletteManager.palettes:
		var name_lower := String(palette.palette_name).to_lower()
		var is_unlocked := SaveManager.has_palette(name_lower)
		var is_active := palette.palette_name == PaletteManager.current.palette_name

		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)

		# Color preview strip — shows the palette's accent colors
		var preview := HBoxContainer.new()
		preview.add_theme_constant_override("separation", 4)
		var preview_colors := [
			palette.good, palette.good_muted,
			palette.bad, palette.bad_muted,
			palette.accent, palette.accent_muted,
			palette.filler, palette.filler_muted,
		]
		for col: Color in preview_colors:
			var swatch := ColorRect.new()
			swatch.custom_minimum_size = Vector2(28, 16)
			swatch.color = col
			preview.add_child(swatch)
		cell.add_child(preview)

		# Main button
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 52)
		if _bold_font:
			btn.add_theme_font_override("font", _bold_font)

		if is_active:
			btn.text = "  ● %s    [ACTIVE]" % palette.palette_name
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
		elif is_unlocked:
			btn.text = "  ○ %s    ▸ EQUIP" % palette.palette_name
			btn.pressed.connect(_on_palette_selected.bind(palette))
			AudioManager.wire_button(btn, &"menu_confirm")
		else:
			var condition := _get_unlock_condition(name_lower)
			btn.text = "  🔒 %s    %s" % [palette.palette_name, condition]
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))

		cell.add_child(btn)
		item_list.add_child(cell)
		buttons.append(btn)

	buttons.append(close_btn)
	UIUtils.chain_focus(buttons)
	# Focus first non-disabled button
	for btn in buttons:
		if not btn.disabled:
			btn.grab_focus()
			return


func _on_palette_selected(palette: PaletteResource) -> void:
	PaletteManager.set_palette_by_name(palette.palette_name)
	AudioManager.play_sfx_2d(&"palette_switch")
	_rebuild()


func _get_unlock_condition(palette_name: String) -> String:
	## Returns a human-readable description of how to unlock this palette.
	match palette_name:
		"midnight":
			var extractions: int = int(SaveManager.get_stat("total_extractions", 0))
			return "Extract 5 times (%d/5)" % extractions
		"noir":
			var kills: int = int(SaveManager.get_stat("total_kills", 0))
			return "Get 50 kills (%d/50)" % kills
		_:
			return "???"
