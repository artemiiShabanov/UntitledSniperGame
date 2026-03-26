extends Control
## Ammo shop panel — buy ammo with credits, view inventory.
## Built dynamically from available AmmoType resources.

signal shop_closed

@onready var credits_label: Label = $VBox/CreditsLabel
@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/CloseButton

## Cached ammo types
var _ammo_types: Array[AmmoType] = []
var _row_controls: Dictionary = {}  ## { ammo_id: { "owned": Label, "buy_btn": Button } }


func _ready() -> void:
	close_btn.pressed.connect(func(): shop_closed.emit())
	AudioManager.wire_button(close_btn, &"menu_cancel")
	_ammo_types = AmmoRegistry.get_all_types()


func open() -> void:
	visible = true
	_rebuild_ui()


func _rebuild_ui() -> void:
	# Clear old rows
	for child in item_list.get_children():
		child.queue_free()
	_row_controls.clear()

	_update_credits_label()

	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})

	for ammo in _ammo_types:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Color indicator
		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(16, 16)
		color_rect.color = ammo.tracer_color
		row.add_child(color_rect)

		# Name
		var name_label := Label.new()
		name_label.text = ammo.ammo_name
		name_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_label)

		# Price
		var price_label := Label.new()
		price_label.text = "$%d/rd" % ammo.cost_per_round
		price_label.custom_minimum_size = Vector2(60, 0)
		price_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		row.add_child(price_label)

		# Owned count
		var owned_label := Label.new()
		var owned: int = inv.get(ammo.ammo_id, 0)
		owned_label.text = "Owned: %d" % owned
		owned_label.custom_minimum_size = Vector2(80, 0)
		row.add_child(owned_label)

		# Buy buttons
		for amount in [1, 5, 10]:
			var btn := Button.new()
			btn.text = "+%d" % amount
			btn.custom_minimum_size = Vector2(40, 0)
			btn.pressed.connect(_on_buy.bind(ammo, amount))
			row.add_child(btn)

		item_list.add_child(row)
		AudioManager.wire_buttons(row)
		_row_controls[ammo.ammo_id] = { "owned": owned_label, "row": row }

	_update_button_states()


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

	# Update UI
	_update_credits_label()
	if _row_controls.has(ammo.ammo_id):
		var owned: int = inv.get(ammo.ammo_id, 0)
		_row_controls[ammo.ammo_id]["owned"].text = "Owned: %d" % owned
	_update_button_states()


func _update_credits_label() -> void:
	credits_label.text = "Credits: $%d" % SaveManager.get_credits()


func _update_button_states() -> void:
	## Disable buy buttons the player can't afford.
	var credits: int = SaveManager.get_credits()
	for ammo in _ammo_types:
		if not _row_controls.has(ammo.ammo_id):
			continue
		var row: HBoxContainer = _row_controls[ammo.ammo_id]["row"]
		# Buy buttons are the last 3 children
		var children := row.get_children()
		var amounts := [1, 5, 10]
		for i in range(3):
			var btn_index := children.size() - 3 + i
			var btn: Button = children[btn_index]
			btn.disabled = credits < ammo.cost_per_round * amounts[i]
