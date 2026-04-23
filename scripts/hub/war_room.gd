extends Control
## War Room panel — displays 6 army upgrades with unlock status.
## Each upgrade shows its paired opportunity requirement.

signal panel_closed

@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _bold_font: Font = null


func _ready() -> void:
	close_btn.pressed.connect(func(): panel_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_bold_font = PaletteTheme.bold_font
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		if visible:
			_rebuild()
	)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		panel_closed.emit()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_rebuild()


func _rebuild() -> void:
	UIUtils.clear_children(item_list)

	var upgrades := ArmyUpgradeRegistry.get_all()

	for upgrade in upgrades:
		var is_unlocked := SaveManager.is_army_upgrade_unlocked(upgrade.id)
		var cell := _build_upgrade_cell(upgrade, is_unlocked)
		item_list.add_child(cell)


func _build_upgrade_cell(upgrade: ArmyUpgrade, is_unlocked: bool) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)

	# Title row.
	var title := Label.new()
	if is_unlocked:
		title.text = "✓  %s" % upgrade.name.to_upper()
		title.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	else:
		title.text = "◇  %s" % upgrade.name.to_upper()
		title.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	if _bold_font:
		title.add_theme_font_override("font", _bold_font)
	cell.add_child(title)

	# Effect description.
	var desc := Label.new()
	desc.text = "     %s" % upgrade.description
	desc.add_theme_font_size_override("font_size", 22)
	if is_unlocked:
		desc.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
	else:
		desc.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))
	cell.add_child(desc)

	# Visual description.
	if upgrade.visual_description != "":
		var visual := Label.new()
		visual.text = "     %s" % upgrade.visual_description
		visual.add_theme_font_size_override("font_size", 20)
		visual.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))
		visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(visual)

	# Paired opportunity info.
	var opp := OpportunityRegistry.get_opportunity(_find_paired_opportunity(upgrade.id))
	if opp:
		var completions := SaveManager.get_opportunity_completions(opp.id)
		var opp_label := Label.new()
		if is_unlocked:
			opp_label.text = "     Unlocked via: %s (completed %dx)" % [opp.name, completions]
		else:
			opp_label.text = "     Requires: Complete \"%s\" (phases %d-%d)" % [opp.name, opp.phase_range.x, opp.phase_range.y]
		opp_label.add_theme_font_size_override("font_size", 20)
		opp_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		cell.add_child(opp_label)

	# Separator.
	cell.add_child(HSeparator.new())

	return cell


func _find_paired_opportunity(upgrade_id: String) -> String:
	## Find the opportunity that pairs with this upgrade.
	for opp in OpportunityRegistry.get_all():
		if opp.paired_army_upgrade_id == upgrade_id:
			return opp.id
	return ""
