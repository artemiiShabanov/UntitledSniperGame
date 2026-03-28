extends Control
## Main menu — first screen the player sees.

@onready var background: ColorRect = $Background
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
var _logo_texture: Texture2D
var _bg_texture: Texture2D

const HUB_SCENE := "res://scenes/hub/hub.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Load menu art assets
	_logo_texture = _try_load("res://assets/ui/game_logo.png")
	_bg_texture = _try_load("res://assets/ui/menu_background.png")

	# Wire logo above title if available
	if _logo_texture:
		var logo := TextureRect.new()
		logo.texture = _logo_texture
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(400, 100)
		var vbox: VBoxContainer = $VBox
		vbox.add_child(logo)
		vbox.move_child(logo, 0)  # Before title

	# Wire background image behind color rect if available
	if _bg_texture:
		var bg := TextureRect.new()
		bg.texture = _bg_texture
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.modulate.a = 0.3  # Subtle behind palette-colored background
		add_child(bg)
		move_child(bg, 0)  # Behind everything

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	slot_cancel_btn.pressed.connect(_close_slot_panel)
	settings_screen.closed.connect(_on_settings_closed)

	slot_panel.visible = false
	settings_screen.visible = false

	# Wire sounds to all static buttons
	AudioManager.wire_buttons(self)

	# Enable continue only if any save exists
	continue_btn.disabled = not _any_save_exists()

	# Grab focus so arrow keys work immediately
	if not continue_btn.disabled:
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()

	# Palette-driven colors
	_apply_palette()
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _apply_palette())

	# Play hub music on main menu too
	AudioManager.play_music(&"hub_theme")

	# Re-grab focus when window regains focus (alt-tab)
	get_tree().root.focus_entered.connect(_on_window_focus)


func _apply_palette() -> void:
	background.color = Color(PaletteManager.get_color(&"fg_dark"), 0.98)
	title.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_friendly"))
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_shadow_color", Color(PaletteManager.get_color(&"accent_friendly"), 0.15))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_screen.visible:
			# Settings handles its own ESC
			return
		if slot_panel.visible:
			_close_slot_panel()
			get_viewport().set_input_as_handled()


func _any_save_exists() -> bool:
	for i in SaveManager.MAX_SLOTS:
		if SaveManager.slot_exists(i):
			return true
	return false


func _on_new_game() -> void:
	_is_new_game = true
	_populate_slots()
	slot_panel.visible = true
	_focus_slot_panel()


func _on_continue() -> void:
	_is_new_game = false
	_populate_slots()
	slot_panel.visible = true
	_focus_slot_panel()


func _focus_slot_panel() -> void:
	## Chain focus neighbors across all buttons in the slot panel, then focus first.
	var buttons: Array[Button] = []
	_collect_buttons(slot_panel, buttons)
	_chain_focus(buttons)
	for btn in buttons:
		if btn.visible and not btn.disabled:
			btn.grab_focus()
			return


func _collect_buttons(node: Node, out: Array[Button]) -> void:
	if node is Button and node.visible:
		out.append(node)
	for child in node.get_children():
		_collect_buttons(child, out)


func _chain_focus(buttons: Array[Button]) -> void:
	if buttons.size() < 2:
		return
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_top = buttons[(i - 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()


func _on_settings() -> void:
	settings_screen.open()


func _on_settings_closed() -> void:
	new_game_btn.grab_focus()


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
		AudioManager.wire_buttons(row)


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


func _on_window_focus() -> void:
	## After alt-tab, re-grab focus so keyboard navigation keeps working.
	if slot_panel.visible:
		_focus_slot_panel()
	elif settings_screen.visible:
		pass  # Settings grabs its own focus
	elif not continue_btn.disabled:
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()


static func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _close_slot_panel() -> void:
	slot_panel.visible = false
	if not continue_btn.disabled:
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()
