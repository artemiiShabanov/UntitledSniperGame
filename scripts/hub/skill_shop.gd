extends Control
## Skill Shop — purchase tiered skills with XP.
## Shows all 4 skills with current tier, next tier cost, and cumulative bonuses.

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
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		if visible:
			_refresh()
	)


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
		var current_tier := SaveManager.get_skill_tier(skill.id)
		var max_tier := skill.get_max_tier()

		# Skill header with icon.
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

		# Tier progress bar.
		var tier_text := "     Tier: %d / %d" % [current_tier, max_tier]
		var tier_label := Label.new()
		tier_label.text = tier_text
		tier_label.add_theme_font_size_override("font_size", 22)
		tier_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
		item_list.add_child(tier_label)

		# Current bonuses.
		if current_tier > 0:
			var bonus := skill.get_tier_stat_bonus(current_tier)
			var bonus_text := _format_stat_bonus(bonus)
			if bonus_text != "":
				var bonus_label := Label.new()
				bonus_label.text = "     Current: " + bonus_text
				bonus_label.add_theme_font_size_override("font_size", 22)
				bonus_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY))
				item_list.add_child(bonus_label)

		# Next tier button.
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 56)
		if _bold_font:
			btn.add_theme_font_override("font", _bold_font)

		if current_tier >= max_tier:
			btn.text = "  ✓  MAX TIER"
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
		else:
			var next_tier := current_tier + 1
			var cost := skill.get_tier_cost(next_tier)
			var desc := skill.get_tier_description(next_tier)
			var can_afford := SaveManager.get_xp() >= cost

			btn.text = "  ◆  Tier %d: %s    %d XP" % [next_tier, desc, cost]
			if can_afford:
				btn.pressed.connect(_on_skill_pressed.bind(skill, next_tier))
				AudioManager.wire_button(btn, &"menu_confirm")
			else:
				btn.text += "  (need %d more)" % (cost - SaveManager.get_xp())
				btn.disabled = true

		item_list.add_child(btn)
		buttons.append(btn)

		# Separator.
		item_list.add_child(HSeparator.new())

	buttons.append(close_btn)
	UIUtils.chain_focus(buttons)
	if buttons.size() > 0:
		buttons[0].grab_focus()


## ── Buy confirmation ────────────────────────────────────────────────────────

func _on_skill_pressed(skill: PlayerSkill, tier: int) -> void:
	_close_confirm()

	var cost := skill.get_tier_cost(tier)
	var desc := skill.get_tier_description(tier)

	_confirm_popup = PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_confirm_popup.add_child(vbox)

	var title := Label.new()
	title.text = "UNLOCK %s TIER %d?" % [skill.skill_name.to_upper(), tier]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	if _bold_font:
		title.add_theme_font_override("font", _bold_font)
	vbox.add_child(title)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	vbox.add_child(desc_label)

	var cost_label := Label.new()
	cost_label.text = "Cost: %d XP" % cost
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
	confirm_btn.pressed.connect(_on_buy_confirmed.bind(skill.id))
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


func _on_buy_confirmed(skill_id: String) -> void:
	if SaveManager.purchase_skill_tier(skill_id):
		AudioManager.play_sfx_2d(&"menu_confirm")
	_close_confirm()
	_refresh()


func _format_stat_bonus(bonus: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in bonus:
		var val = bonus[key]
		var display := key.replace("_", " ").capitalize()
		if val is float:
			if absf(val) < 1.0:
				parts.append("%s %+.0f%%" % [display, val * 100.0])
			else:
				parts.append("%s %+.1f" % [display, val])
		elif val is int:
			parts.append("%s %+d" % [display, val])
	return " · ".join(parts)
