extends Control
## Mod Shop panel — browse, buy, and equip rifle modifications.
## Each mod is a PanelContainer cell with a clickable Button + detail labels.
## Buying requires confirmation.

signal shop_closed

@onready var credits_label: Label = $VBox/CreditsLabel
@onready var tab_bar: HBoxContainer = $VBox/TabBar
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _current_slot: String = "barrel"
var _confirm_popup: PanelContainer = null
var _bold_font: Font = null
var _mod_buttons: Dictionary = {}  ## { mod_id: Button }
var _slot_icons: Dictionary = {}  ## { slot: Texture2D }


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_bold_font = PaletteTheme.bold_font
	for slot in ModRegistry.SLOTS:
		var icon_path := "res://assets/icons/mods/slot_%s.png" % slot
		if ResourceLoader.exists(icon_path):
			_slot_icons[slot] = load(icon_path)
	_build_tabs()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and _confirm_popup:
		_close_confirm_and_refocus()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_current_slot = "barrel"
	_close_confirm()
	_refresh()
	var tabs := tab_bar.get_children()
	if tabs.size() > 0:
		tabs[0].grab_focus()


func _build_tabs() -> void:
	for slot in ModRegistry.SLOTS:
		var btn := Button.new()
		if _slot_icons.has(slot):
			btn.icon = _slot_icons[slot]
			btn.add_theme_constant_override("icon_max_width", 28)
		btn.text = slot.capitalize()
		btn.pressed.connect(_on_tab_selected.bind(slot))
		AudioManager.wire_button(btn)
		tab_bar.add_child(btn)


func _on_tab_selected(slot: String) -> void:
	_current_slot = slot
	_close_confirm()
	_refresh()


func _refresh() -> void:
	_update_credits_label()
	_update_tab_highlight()
	_rebuild_mod_list()


func _update_credits_label() -> void:
	credits_label.text = "Credits: $%d" % SaveManager.get_credits()
	credits_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))


func _update_tab_highlight() -> void:
	var tabs := tab_bar.get_children()
	for i in range(tabs.size()):
		var btn: Button = tabs[i]
		var slot: String = ModRegistry.SLOTS[i]
		if slot == _current_slot:
			btn.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		else:
			btn.remove_theme_color_override("font_color")


func _rebuild_mod_list() -> void:
	UIUtils.clear_children(item_list)
	_mod_buttons.clear()

	var mods := ModRegistry.get_mods_for_slot(_current_slot)
	var equipped_id: String = SaveManager.get_equipped_mod(_current_slot)

	var all_buttons: Array[Button] = []
	for tab_btn in tab_bar.get_children():
		all_buttons.append(tab_btn)

	for mod in mods:
		var cell := _build_mod_cell(mod, equipped_id)
		item_list.add_child(cell)
		all_buttons.append(_mod_buttons[mod.id])

	all_buttons.append(close_btn)
	UIUtils.chain_focus(all_buttons)

	# Focus first mod card
	for mod in mods:
		if _mod_buttons.has(mod.id):
			_mod_buttons[mod.id].grab_focus()
			break


func _build_mod_cell(mod: RifleMod, equipped_id: String) -> VBoxContainer:
	## Each mod cell is a VBox: Button (name + status) + detail labels.
	var is_equipped: bool = mod.id == equipped_id
	var is_owned: bool = SaveManager.owns_mod(mod.id)

	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)

	# Top row: icon + button side by side
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)

	if mod.icon:
		var icon := TextureRect.new()
		icon.texture = mod.icon
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		top_row.add_child(icon)

	# Main button — clickable row
	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _bold_font:
		btn.add_theme_font_override("font", _bold_font)

	var status: String
	if is_equipped:
		status = "[EQUIPPED]"
		btn.disabled = true
		btn.add_theme_color_override("font_disabled_color", PaletteManager.get_color(PaletteManager.SLOT_REWARD))
	elif is_owned:
		status = "▸ EQUIP"
		btn.pressed.connect(_on_equip.bind(mod))
		AudioManager.wire_button(btn)
	else:
		status = "$%d" % mod.cost if mod.cost > 0 else "FREE"
		btn.disabled = SaveManager.get_credits() < mod.cost
		btn.pressed.connect(_on_buy_requested.bind(mod))
		AudioManager.wire_button(btn, &"menu_confirm")

	btn.text = "  %s    %s" % [mod.mod_name, status]
	top_row.add_child(btn)
	cell.add_child(top_row)
	_mod_buttons[mod.id] = btn

	# Indent for detail labels (aligned with button text past the icon)
	var indent := "     "
	if mod.icon:
		indent = "            "  # Extra indent to clear icon width

	# Description label
	var desc := Label.new()
	desc.text = "%s%s" % [indent, mod.description]
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))
	cell.add_child(desc)

	# Stats label
	var stats_text := _format_stats(mod)
	if stats_text != "":
		var stats := Label.new()
		stats.text = "%s%s" % [indent, stats_text]
		stats.add_theme_font_size_override("font_size", 22)
		stats.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		cell.add_child(stats)

	return cell


## ── Buy confirmation ────────────────────────────────────────────────────────

func _on_buy_requested(mod: RifleMod) -> void:
	_close_confirm()

	_confirm_popup = PanelContainer.new()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_confirm_popup.add_child(vbox)

	var title := Label.new()
	title.text = "BUY %s?" % mod.mod_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	if _bold_font:
		title.add_theme_font_override("font", _bold_font)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = mod.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var stats_text := _format_stats(mod)
	if stats_text != "":
		var stats := Label.new()
		stats.text = stats_text
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		stats.add_theme_font_size_override("font_size", 22)
		vbox.add_child(stats)

	var cost_label := Label.new()
	cost_label.text = "Cost: $%d" % mod.cost if mod.cost > 0 else "Cost: FREE"
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
	confirm_btn.text = "CONFIRM"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.pressed.connect(_on_buy_confirmed.bind(mod))
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


func _on_buy_confirmed(mod: RifleMod) -> void:
	if SaveManager.purchase_mod(mod.id, mod.cost):
		AudioManager.play_sfx_2d(&"menu_confirm")
	_close_confirm()
	_refresh()


func _on_equip(mod: RifleMod) -> void:
	SaveManager.equip_mod(mod.id)
	AudioManager.play_sfx_2d(&"menu_confirm")
	_refresh()


func _format_stats(mod: RifleMod) -> String:
	var parts: Array[String] = []
	for key: String in mod.stat_overrides:
		var val: Variant = mod.stat_overrides[key]
		var display_name := key.replace("_", " ").capitalize()
		if val is float:
			parts.append("%s: %s" % [display_name, "%.2f" % val])
		else:
			parts.append("%s: %s" % [display_name, str(val)])
	return " | ".join(parts)

