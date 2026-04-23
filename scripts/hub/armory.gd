extends Control
## Armory panel — browse, equip, and unequip procedural mods by slot.
## Shows mod inventory with durability, stats, and rarity. 5-per-slot cap.
## Replaces the old mod_shop.gd (no buying — mods are earned via extraction).

signal shop_closed
signal mod_equipped

@onready var xp_label: Label = $VBox/XPLabel
@onready var tab_bar: HBoxContainer = $VBox/TabBar
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _current_slot: String = "barrel"
var _bold_font: Font = null


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_bold_font = PaletteTheme.bold_font
	_build_tabs()
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void:
		if visible:
			_refresh()
	)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		shop_closed.emit()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_current_slot = "barrel"
	_refresh()
	var tabs := tab_bar.get_children()
	if tabs.size() > 0:
		tabs[0].grab_focus()


func _build_tabs() -> void:
	for slot in RifleMod.SLOT_NAMES:
		var btn := Button.new()
		btn.text = slot.capitalize()
		btn.pressed.connect(_on_tab_selected.bind(slot))
		AudioManager.wire_button(btn)
		tab_bar.add_child(btn)


func _on_tab_selected(slot: String) -> void:
	_current_slot = slot
	_refresh()


func _refresh() -> void:
	_update_xp_label()
	_update_tab_highlight()
	_rebuild_mod_list()


func _update_xp_label() -> void:
	xp_label.text = "XP: %d" % SaveManager.get_xp()
	xp_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))


func _update_tab_highlight() -> void:
	var tabs := tab_bar.get_children()
	for i in range(tabs.size()):
		var btn: Button = tabs[i]
		var slot: String = RifleMod.SLOT_NAMES[i]
		if slot == _current_slot:
			btn.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
		else:
			btn.remove_theme_color_override("font_color")


func _rebuild_mod_list() -> void:
	UIUtils.clear_children(item_list)

	var equipped: Dictionary = SaveManager.get_equipped_loadout()
	var equipped_index: int = equipped.get(_current_slot, -1)
	var slot_mods: Array = SaveManager.get_mods_for_slot(_current_slot)

	# Slot header.
	var header := Label.new()
	header.text = "%s  (%d/5)" % [_current_slot.to_upper(), slot_mods.size()]
	header.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	if _bold_font:
		header.add_theme_font_override("font", _bold_font)
	item_list.add_child(header)

	if slot_mods.is_empty():
		var empty := Label.new()
		empty.text = "  No mods. Earn mods by extracting successfully."
		empty.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_MID))
		item_list.add_child(empty)
		return

	var all_buttons: Array[Button] = []
	for tab_btn in tab_bar.get_children():
		all_buttons.append(tab_btn)

	for entry in slot_mods:
		var idx: int = entry["index"]
		var mod_data: Dictionary = entry["mod_data"]
		var is_equipped: bool = idx == equipped_index
		var cell := _build_mod_cell(idx, mod_data, is_equipped)
		item_list.add_child(cell)
		# Find the button in the cell.
		for child in cell.get_children():
			if child is Button:
				all_buttons.append(child)

	all_buttons.append(close_btn)
	UIUtils.chain_focus(all_buttons)


func _build_mod_cell(idx: int, mod_data: Dictionary, is_equipped: bool) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)

	var rarity: int = mod_data.get("rarity", 0)
	var durability: int = mod_data.get("durability", 0)
	var max_durability: int = mod_data.get("max_durability", 0)
	var stats: Dictionary = mod_data.get("stats", {})
	var rarity_name: String = RifleMod.RARITY_NAMES[rarity]

	# Rarity color.
	var rarity_color: Color
	match rarity:
		0: rarity_color = PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT)
		1: rarity_color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_FRIENDLY)
		2: rarity_color = PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT)
		_: rarity_color = PaletteManager.get_color(PaletteManager.SLOT_REWARD)

	# Main button.
	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 56)
	if _bold_font:
		btn.add_theme_font_override("font", _bold_font)

	if is_equipped:
		btn.text = "  [EQUIPPED]  %s  %d/%d runs" % [rarity_name, durability, max_durability]
		btn.pressed.connect(_on_unequip.bind(_current_slot))
		btn.add_theme_color_override("font_color", rarity_color)
		AudioManager.wire_button(btn)
	else:
		btn.text = "  EQUIP  %s  %d/%d runs" % [rarity_name, durability, max_durability]
		btn.pressed.connect(_on_equip.bind(idx))
		AudioManager.wire_button(btn)

	cell.add_child(btn)

	# Stats line.
	var stat_parts: Array[String] = []
	for key: String in stats:
		var val = stats[key]
		if val is bool:
			if val:
				stat_parts.append(key.replace("_", " ").capitalize())
		elif val is float:
			var display := key.replace("_", " ").capitalize()
			if key.ends_with("_mult") or key in ["velocity", "accuracy", "falloff", "move_speed", "headshot_damage"]:
				stat_parts.append("%s: x%.2f" % [display, val])
			elif key in ["fov", "cycle_time"]:
				stat_parts.append("%s: %.1f" % [display, val])
			elif key == "capacity":
				stat_parts.append("%s: +%d" % [display, int(val)])
			else:
				stat_parts.append("%s: %.0f%%" % [display, val * 100.0])

	if stat_parts.size() > 0:
		var stat_label := Label.new()
		stat_label.text = "     " + " | ".join(stat_parts)
		stat_label.add_theme_font_size_override("font_size", 22)
		stat_label.add_theme_color_override("font_color", rarity_color)
		cell.add_child(stat_label)

	return cell


func _on_equip(index: int) -> void:
	SaveManager.equip_mod(index)
	AudioManager.play_sfx_2d(&"menu_confirm")
	_refresh()
	mod_equipped.emit()


func _on_unequip(slot_name: String) -> void:
	SaveManager.unequip_mod(slot_name)
	AudioManager.play_sfx_2d(&"menu_confirm")
	_refresh()
	mod_equipped.emit()
