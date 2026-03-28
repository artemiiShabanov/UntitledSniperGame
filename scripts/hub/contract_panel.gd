extends Control
## Contract selection panel — pick one contract before deploying.
## Shows a random selection of available contracts for the selected level.

signal contract_selected(contract: Contract)  ## null means "no contract"

@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var close_btn: Button = $VBox/SkipButton

var _offered: Array[Contract] = []
var _level_path: String = ""


func _ready() -> void:
	close_btn.pressed.connect(func(): contract_selected.emit(null))
	AudioManager.wire_button(close_btn, &"menu_cancel")


func open(level_path: String = "") -> void:
	_level_path = level_path
	visible = true
	_rebuild()


func _rebuild() -> void:
	for child in item_list.get_children():
		child.queue_free()

	_offered = ContractRegistry.get_random_selection(_level_path)

	for contract in _offered:
		var row := _build_contract_row(contract)
		item_list.add_child(row)


func _build_contract_row(contract: Contract) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var can_afford: bool = contract.cost == 0 or SaveManager.get_credits() >= contract.cost

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = contract.contract_name
	name_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = contract.description
	desc_label.add_theme_color_override("font_color", PaletteManager.get_color(&"bg_light"))
	desc_label.add_theme_font_size_override("font_size", 12)
	info.add_child(desc_label)

	# Reward + cost line
	var reward_parts: Array[String] = []
	if contract.bonus_credits > 0:
		reward_parts.append("+$%d" % contract.bonus_credits)
	if contract.bonus_xp > 0:
		reward_parts.append("+%d XP" % contract.bonus_xp)
	var reward_label := Label.new()
	reward_label.text = "Reward: " + " ".join(reward_parts)
	reward_label.add_theme_color_override("font_color", PaletteManager.get_color(&"reward"))
	reward_label.add_theme_font_size_override("font_size", 12)
	info.add_child(reward_label)

	hbox.add_child(info)

	# Accept button with cost
	var btn := Button.new()
	if contract.cost > 0:
		btn.text = "Accept ($%d)" % contract.cost
		btn.disabled = not can_afford
	else:
		btn.text = "Accept (Free)"
	btn.custom_minimum_size = Vector2(110, 0)
	btn.pressed.connect(func(): _accept_contract(contract))
	AudioManager.wire_button(btn, &"menu_confirm")
	hbox.add_child(btn)

	return panel


func _accept_contract(contract: Contract) -> void:
	if contract.cost > 0:
		if SaveManager.get_credits() < contract.cost:
			return
		SaveManager.add_credits(-contract.cost)
		SaveManager.save()
	contract_selected.emit(contract)
