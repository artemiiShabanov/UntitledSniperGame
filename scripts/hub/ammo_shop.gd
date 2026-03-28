extends Control
## Ammo shop panel — buy ammo with credits, view inventory.
## Each ammo type shows as a label row + buy buttons always visible below it.

signal shop_closed

@onready var credits_label: Label = $VBox/CreditsLabel
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

## Cached ammo types
var _ammo_types: Array[AmmoType] = []
var _row_controls: Dictionary = {}  ## { ammo_id: { "owned": Label, "buttons": Array[Button] } }
var _bold_font: Font = null


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_ammo_types = AmmoRegistry.get_all_types()
	_bold_font = load("res://assets/fonts/JetBrainsMono-Bold.ttf")


func open() -> void:
	visible = true
	_rebuild_ui()


func _rebuild_ui() -> void:
	for child in item_list.get_children():
		child.queue_free()
	_row_controls.clear()

	_update_credits_label()

	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})
	var all_buttons: Array[Button] = []

	for ammo in _ammo_types:
		# Header row: icon + name, price, owned
		var owned: int = inv.get(ammo.ammo_id, 0)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 12)

		if ammo.icon:
			var icon := TextureRect.new()
			icon.texture = ammo.icon
			icon.custom_minimum_size = Vector2(32, 32)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			header_row.add_child(icon)

		var header := Label.new()
		header.text = "%s    $%d/rd    Owned: %d" % [ammo.ammo_name.to_upper(), ammo.cost_per_round, owned]
		if _bold_font:
			header.add_theme_font_override("font", _bold_font)
		header_row.add_child(header)
		item_list.add_child(header_row)

		# Buy buttons row
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		item_list.add_child(btn_row)

		var row_buttons: Array[Button] = []
		var amounts := [1, 5, 10, 25]
		for amount in amounts:
			var cost: int = ammo.cost_per_round * amount
			var btn := Button.new()
			btn.text = "+%d  ($%d)" % [amount, cost]
			btn.custom_minimum_size = Vector2(0, 48)
			btn.pressed.connect(_on_buy.bind(ammo, amount))
			AudioManager.wire_button(btn, &"menu_confirm")
			btn_row.add_child(btn)
			row_buttons.append(btn)
			all_buttons.append(btn)

		# Chain left/right within this row
		for i in range(row_buttons.size()):
			row_buttons[i].focus_neighbor_left = row_buttons[(i - 1) % row_buttons.size()].get_path()
			row_buttons[i].focus_neighbor_right = row_buttons[(i + 1) % row_buttons.size()].get_path()

		# Separator between ammo types
		var sep := HSeparator.new()
		item_list.add_child(sep)

		_row_controls[ammo.ammo_id] = { "owned": header, "buttons": row_buttons, "ammo": ammo }

	all_buttons.append(close_btn)
	_chain_focus(all_buttons)
	if all_buttons.size() > 0:
		all_buttons[0].grab_focus()

	_update_affordability()


func _on_buy(ammo: AmmoType, amount: int) -> void:
	var total_cost: int = ammo.cost_per_round * amount
	if SaveManager.get_credits() < total_cost:
		return

	AudioManager.play_sfx_2d(&"menu_confirm")
	SaveManager.add_credits(-total_cost)

	if not SaveManager.data.has("ammo_inventory"):
		SaveManager.data["ammo_inventory"] = {}
	var inv: Dictionary = SaveManager.data["ammo_inventory"]
	inv[ammo.ammo_id] = inv.get(ammo.ammo_id, 0) + amount
	SaveManager.save()

	# Update header text
	if _row_controls.has(ammo.ammo_id):
		var owned: int = inv.get(ammo.ammo_id, 0)
		_row_controls[ammo.ammo_id]["owned"].text = "%s    $%d/rd    Owned: %d" % [ammo.ammo_name.to_upper(), ammo.cost_per_round, owned]

	_update_credits_label()
	_update_affordability()


func _update_credits_label() -> void:
	credits_label.text = "Credits: $%d" % SaveManager.get_credits()
	credits_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))


func _update_affordability() -> void:
	var credits: int = SaveManager.get_credits()
	var amounts := [1, 5, 10, 25]
	for ammo in _ammo_types:
		if not _row_controls.has(ammo.ammo_id):
			continue
		var buttons: Array = _row_controls[ammo.ammo_id]["buttons"]
		for i in range(buttons.size()):
			buttons[i].disabled = credits < ammo.cost_per_round * amounts[i]


func _chain_focus(buttons: Array[Button]) -> void:
	if buttons.size() < 2:
		return
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_top = buttons[(i - 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
