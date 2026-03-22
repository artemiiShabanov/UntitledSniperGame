extends Control
## Main menu — first screen the player sees.

@onready var title: Label = $VBox/Title
@onready var new_game_btn: Button = $VBox/NewGameButton
@onready var continue_btn: Button = $VBox/ContinueButton
@onready var settings_btn: Button = $VBox/SettingsButton
@onready var quit_btn: Button = $VBox/QuitButton
@onready var slot_panel: PanelContainer = $SlotPanel
@onready var slot_list: VBoxContainer = $SlotPanel/VBox/SlotList
@onready var slot_cancel_btn: Button = $SlotPanel/VBox/CancelButton
@onready var settings_screen: PanelContainer = $SettingsScreen

var _is_new_game: bool = false  ## True = create new, False = load existing

const HUB_SCENE := "res://scenes/hub/hub.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	slot_cancel_btn.pressed.connect(_close_slot_panel)
	settings_screen.closed.connect(_on_settings_closed)

	slot_panel.visible = false
	settings_screen.visible = false

	# Enable continue only if any save exists
	continue_btn.disabled = not _any_save_exists()


func _any_save_exists() -> bool:
	for i in SaveManager.MAX_SLOTS:
		if SaveManager.slot_exists(i):
			return true
	return false


func _on_new_game() -> void:
	_is_new_game = true
	_populate_slots()
	slot_panel.visible = true


func _on_continue() -> void:
	_is_new_game = false
	_populate_slots()
	slot_panel.visible = true


func _on_settings() -> void:
	settings_screen.open()


func _on_settings_closed() -> void:
	pass  # Settings auto-saves on close


func _on_quit() -> void:
	get_tree().quit()


## ── Slot Selection ──────────────────────────────────────────────────────────

func _populate_slots() -> void:
	for child in slot_list.get_children():
		child.queue_free()

	for i in SaveManager.MAX_SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		if SaveManager.slot_exists(i):
			var summary := SaveManager.get_slot_summary(i)
			var info := Label.new()
			info.text = "Slot %d — $%d | %d XP | %d extractions" % [
				i + 1,
				summary.get("credits", 0),
				summary.get("xp", 0),
				summary.get("total_extractions", 0),
			]
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			if _is_new_game:
				# Overwrite existing slot
				var btn := Button.new()
				btn.text = "Overwrite"
				btn.pressed.connect(_on_slot_selected.bind(i))
				row.add_child(btn)
			else:
				# Load existing slot
				var load_btn := Button.new()
				load_btn.text = "Load"
				load_btn.pressed.connect(_on_slot_selected.bind(i))
				row.add_child(load_btn)

			# Delete button
			var del_btn := Button.new()
			del_btn.text = "Delete"
			del_btn.pressed.connect(_on_slot_delete.bind(i))
			row.add_child(del_btn)
		else:
			var info := Label.new()
			info.text = "Slot %d — Empty" % [i + 1]
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			if _is_new_game:
				var btn := Button.new()
				btn.text = "Create"
				btn.pressed.connect(_on_slot_selected.bind(i))
				row.add_child(btn)

		slot_list.add_child(row)


func _on_slot_selected(slot: int) -> void:
	if _is_new_game:
		SaveManager.new_game(slot)
	else:
		SaveManager.load_slot(slot)
	slot_panel.visible = false
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_slot_delete(slot: int) -> void:
	SaveManager.delete_slot(slot)
	_populate_slots()
	continue_btn.disabled = not _any_save_exists()


func _close_slot_panel() -> void:
	slot_panel.visible = false
