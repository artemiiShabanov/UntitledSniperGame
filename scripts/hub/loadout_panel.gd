extends Control
## Pre-run loadout selection — choose which ammo to bring from inventory.
## Opens after selecting a level on the deploy board.

signal deploy_confirmed(loadout: Dictionary)
signal loadout_cancelled

@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var deploy_btn: Button = $VBox/DeployButton
@onready var cancel_btn: Button = $VBox/CancelButton

## Cached ammo types
var _ammo_types: Array[AmmoType] = []
## { ammo_id: HSlider } — one slider per type
var _sliders: Dictionary = {}
## { ammo_id: Label } — shows "X / Y" selected vs owned
var _count_labels: Dictionary = {}


func _ready() -> void:
	deploy_btn.pressed.connect(_on_deploy)
	cancel_btn.pressed.connect(func(): loadout_cancelled.emit())
	_ammo_types = AmmoRegistry.get_all_types()


func open() -> void:
	visible = true
	_rebuild_ui()


func _rebuild_ui() -> void:
	for child in item_list.get_children():
		child.queue_free()
	_sliders.clear()
	_count_labels.clear()

	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})

	for ammo in _ammo_types:
		var owned: int = inv.get(ammo.ammo_id, 0)
		if owned <= 0:
			continue  # Don't show types with zero inventory

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

		# Count label
		var count_label := Label.new()
		count_label.text = "%d / %d" % [owned, owned]
		count_label.custom_minimum_size = Vector2(70, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(count_label)
		_count_labels[ammo.ammo_id] = count_label

		# Slider
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = owned
		slider.value = owned  # Default: bring all
		slider.step = 1
		slider.custom_minimum_size = Vector2(150, 0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ammo_id := ammo.ammo_id  # Capture for lambda
		slider.value_changed.connect(func(v: float):
			_count_labels[ammo_id].text = "%d / %d" % [int(v), owned]
		)
		row.add_child(slider)
		_sliders[ammo.ammo_id] = slider

		item_list.add_child(row)

	# If inventory is completely empty, show a message
	if _sliders.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No ammo in inventory!\nBuy ammo at the Ammo Crate first."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(empty_label)
		deploy_btn.disabled = true
	else:
		deploy_btn.disabled = false


func _on_deploy() -> void:
	var loadout: Dictionary = {}
	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})

	for ammo_id in _sliders:
		var slider: HSlider = _sliders[ammo_id]
		var take: int = int(slider.value)
		if take > 0:
			loadout[ammo_id] = take
			# Remove from inventory
			inv[ammo_id] = inv.get(ammo_id, 0) - take
			if inv[ammo_id] <= 0:
				inv.erase(ammo_id)

	SaveManager.save()
	deploy_confirmed.emit(loadout)
