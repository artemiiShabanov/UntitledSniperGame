extends Control
## Skill Shop — unlock permanent abilities with XP.
## Each skill is a Button card with name, cost, and status.
## Clicking an affordable skill shows a confirmation popup with full details.

signal shop_closed

@onready var xp_label: Label = $VBox/XPLabel
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _bold_font: Font = null
var _confirm_popup: PanelContainer = null


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_bold_font = PaletteTheme.bold_font


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and _confirm_popup:
		_close_confirm_and_refocus()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_close_confirm()
	_refresh()


func _refresh() -> void:
	_update_xp_label()
	_rebuild_skill_list()


func _update_xp_label() -> void:
	xp_label.text = "XP: %d" % SaveManager.get_xp()
	xp_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))


func _rebuild_skill_list() -> void:
	UIUtils.clear_children(item_list)

	var skills := SkillRegistry.get_all_skills()
	var buttons: Array[Button] = []

	for skill in skills:
		# Skill icon
		if skill.icon:
			var icon_row := HBoxContainer.new()
			icon_row.add_theme_constant_override("separation", 12)
			var icon := TextureRect.new()
			icon.texture = skill.icon
			icon.custom_minimum_size = Vector2(48, 48)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_row.add_child(icon)
			var skill_title := Label.new()
			skill_title.text = skill.skill_name.to_upper()
			skill_title.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
			if _bold_font:
				skill_title.add_theme_font_override("font", _bold_font)
			icon_row.add_child(skill_title)
			item_list.add_child(icon_row)

		var btn := _build_skill_button(skill)
		item_list.add_child(btn)
		buttons.append(btn)

		# Add a detail label below each button
		var detail := _build_detail_label(skill)
		item_list.add_child(detail)

	buttons.append(close_btn)
	UIUtils.chain_focus(buttons)
	if buttons.size() > 0:
		buttons[0].grab_focus()


func _build_skill_button(skill: PlayerSkill) -> Button:
	var owned: bool = SaveManager.has_skill(skill.id)
	var can_afford: bool = SaveManager.get_xp() >= skill.cost

	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 64)
	if _bold_font:
		btn.add_theme_font_override("font", _bold_font)

	if owned:
		btn.text = "  ✓  %s    UNLOCKED" % skill.skill_name.to_upper()
		btn.disabled = true
		btn.add_theme_color_override("font_disabled_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	elif can_afford:
		btn.text = "  ◆  %s    %d XP" % [skill.skill_name.to_upper(), skill.cost]
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		AudioManager.wire_button(btn, &"menu_confirm")
	else:
		btn.text = "  ◇  %s    %d XP  (need %d more)" % [skill.skill_name.to_upper(), skill.cost, skill.cost - SaveManager.get_xp()]
		btn.disabled = true

	return btn


func _build_detail_label(skill: PlayerSkill) -> Label:
	## Small description shown below each skill button.
	var label := Label.new()
	var parts: Array[String] = [skill.description]
	var bonus := _format_stat_bonus(skill)
	if bonus != "":
		parts.append(bonus)
	label.text = "     " + " · ".join(parts)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## ── Buy confirmation ────────────────────────────────────────────────────────

func _on_skill_pressed(skill: PlayerSkill) -> void:
	_close_confirm()

	_confirm_popup = PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_confirm_popup.add_child(vbox)

	var title := Label.new()
	title.text = "UNLOCK %s?" % skill.skill_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	if _bold_font:
		title.add_theme_font_override("font", _bold_font)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = skill.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var bonus_text := _format_stat_bonus(skill)
	if bonus_text != "":
		var bonus := Label.new()
		bonus.text = bonus_text
		bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		vbox.add_child(bonus)

	var cost_label := Label.new()
	cost_label.text = "Cost: %d XP" % skill.cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
	if _bold_font:
		cost_label.add_theme_font_override("font", _bold_font)
	vbox.add_child(cost_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "UNLOCK"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.pressed.connect(_on_buy_confirmed.bind(skill))
	AudioManager.wire_button(confirm_btn, &"menu_confirm")
	btn_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(180, 56)
	cancel_btn.pressed.connect(_close_confirm_and_refocus)
	AudioManager.wire_button(cancel_btn, &"menu_cancel")
	btn_row.add_child(cancel_btn)

	confirm_btn.focus_neighbor_right = cancel_btn.get_path()
	cancel_btn.focus_neighbor_left = confirm_btn.get_path()

	item_list.add_child(_confirm_popup)
	confirm_btn.grab_focus()


func _close_confirm() -> void:
	if _confirm_popup and is_instance_valid(_confirm_popup):
		_confirm_popup.queue_free()
	_confirm_popup = null


func _close_confirm_and_refocus() -> void:
	_close_confirm()
	_refresh()


func _on_buy_confirmed(skill: PlayerSkill) -> void:
	if SaveManager.purchase_skill(skill.id, skill.cost):
		AudioManager.play_sfx_2d(&"menu_confirm")
	_close_confirm()
	_refresh()


func _format_stat_bonus(skill: PlayerSkill) -> String:
	var parts: Array[String] = []
	for key: String in skill.stat_bonus:
		var val = skill.stat_bonus[key]
		var display := key.replace("_", " ").capitalize()
		if val is float:
			if val < 1.0 and val > 0.0:
				parts.append("%s ×%.1f" % [display, val])
			else:
				parts.append("%s +%.1f" % [display, val])
		elif val is int:
			parts.append("%s +%d" % [display, val])
	return " · ".join(parts)

