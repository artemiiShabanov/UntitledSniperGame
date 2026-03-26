extends Control
## Mod Shop panel — browse, buy, and equip rifle modifications.
## Built dynamically from ModRegistry data.

signal shop_closed

@onready var credits_label: Label = $VBox/CreditsLabel
@onready var tab_bar: HBoxContainer = $VBox/TabBar
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

var _current_slot: String = "barrel"


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_build_tabs()


func open() -> void:
	visible = true
	_current_slot = "barrel"
	_refresh()


func _build_tabs() -> void:
	for slot in ModRegistry.SLOTS:
		var btn := Button.new()
		btn.text = slot.capitalize()
		btn.pressed.connect(_on_tab_selected.bind(slot))
		AudioManager.wire_button(btn)
		tab_bar.add_child(btn)


func _on_tab_selected(slot: String) -> void:
	_current_slot = slot
	_refresh()


func _refresh() -> void:
	_update_credits_label()
	_update_tab_highlight()
	_rebuild_mod_list()


func _update_credits_label() -> void:
	credits_label.text = "Credits: $%d" % SaveManager.get_credits()


func _update_tab_highlight() -> void:
	var tabs := tab_bar.get_children()
	for i in range(tabs.size()):
		var btn: Button = tabs[i]
		var slot: String = ModRegistry.SLOTS[i]
		if slot == _current_slot:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			btn.remove_theme_color_override("font_color")


func _rebuild_mod_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var mods := ModRegistry.get_mods_for_slot(_current_slot)
	var equipped_id: String = SaveManager.get_equipped_mod(_current_slot)

	for mod in mods:
		var row := _build_mod_row(mod, equipped_id)
		item_list.add_child(row)


func _build_mod_row(mod: RifleMod, equipped_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var is_equipped: bool = mod.id == equipped_id
	var is_owned: bool = SaveManager.owns_mod(mod.id)

	# Left side: info
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = mod.mod_name
	if is_equipped:
		name_label.text += "  [EQUIPPED]"
		name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	elif is_owned:
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = mod.description
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)

	# Stats line
	var stats_text := _format_stats(mod)
	if stats_text != "":
		var stats_label := Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		stats_label.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(stats_label)

	hbox.add_child(info_vbox)

	# Right side: action button
	if is_equipped:
		# No button needed — already equipped
		pass
	elif is_owned:
		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.custom_minimum_size = Vector2(80, 0)
		equip_btn.pressed.connect(_on_equip.bind(mod))
		AudioManager.wire_button(equip_btn)
		hbox.add_child(equip_btn)
	else:
		var buy_btn := Button.new()
		if mod.cost == 0:
			buy_btn.text = "FREE"
		else:
			buy_btn.text = "Buy $%d" % mod.cost
		buy_btn.custom_minimum_size = Vector2(80, 0)
		buy_btn.disabled = SaveManager.get_credits() < mod.cost
		buy_btn.pressed.connect(_on_buy.bind(mod))
		AudioManager.wire_button(buy_btn, &"menu_confirm")
		hbox.add_child(buy_btn)

	return panel


func _format_stats(mod: RifleMod) -> String:
	var parts: Array[String] = []
	for key: String in mod.stat_overrides:
		var val = mod.stat_overrides[key]
		var display_name := key.replace("_", " ").capitalize()
		if val is float:
			parts.append("%s: %s" % [display_name, "%.2f" % val])
		else:
			parts.append("%s: %s" % [display_name, str(val)])
	return " | ".join(parts)


func _on_buy(mod: RifleMod) -> void:
	if SaveManager.purchase_mod(mod.id, mod.cost):
		AudioManager.play_sfx_2d(&"menu_confirm")
		_refresh()


func _on_equip(mod: RifleMod) -> void:
	SaveManager.equip_mod(mod.id)
	AudioManager.play_sfx_2d(&"menu_confirm")
	_refresh()
