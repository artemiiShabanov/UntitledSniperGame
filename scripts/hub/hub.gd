extends Node3D
## Hub scene — player walks around, interacts with stations.

## All available levels — add new LevelData resources here
var LEVEL_LIST: Array[String] = [
	"res://data/levels/dev_test_data.tres",
	"res://data/levels/industrial_yard_data.tres",
]

@onready var deploy_board: Interactable = $DeployBoard
@onready var ammo_crate: Interactable = $AmmoCrate
@onready var save_terminal: Interactable = $SaveTerminal
@onready var mod_bench: Interactable = $ModBench
@onready var skill_board: Interactable = $SkillBoard
@onready var stats_terminal: Interactable = $StatsTerminal

## UI layer — holds all station panels + dimmer
@onready var station_ui: CanvasLayer = $StationUI

## UI panels
@onready var deploy_panel: Control = $StationUI/DeployPanel
@onready var ammo_shop: Control = $StationUI/AmmoShop
@onready var loadout_panel: Control = $StationUI/LoadoutPanel
@onready var mod_shop: Control = $StationUI/ModShop
@onready var skill_shop: Control = $StationUI/SkillShop
@onready var contract_panel: Control = $StationUI/ContractPanel
@onready var stats_panel: Control = $StationUI/StatsPanel
@onready var save_feedback: Label = $StationUI/SaveFeedback

## Deploy UI
@onready var mission_list: VBoxContainer = $StationUI/DeployPanel/VBox/MissionList

## Credits display
@onready var credits_label: Label = $StationUI/CreditsLabel

var active_panel: Control = null
var selected_level_path: String = ""
var selected_level_data: LevelData = null
var _level_data_cache: Array[LevelData] = []

## Background dimmer — blocks clicks and darkens 3D view when a panel is open
var _dimmer: ColorRect
## Reference to player for disabling input while panels are open
var _player: CharacterBody3D


func _ready() -> void:
	RunManager._set_game_state(RunManager.GameState.HUB)
	RunManager.is_dead = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Find player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

	# Create dimmer as first child of StationUI so it sits behind panels
	_dimmer = ColorRect.new()
	_dimmer.name = "Dimmer"
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0, 0, 0, 0.7)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP  # Blocks clicks to 3D
	_dimmer.visible = false
	station_ui.add_child(_dimmer)
	station_ui.move_child(_dimmer, 0)  # Behind all panels

	deploy_board.deploy_requested.connect(_on_deploy_requested)
	ammo_crate.loadout_requested.connect(_on_ammo_crate_requested)
	save_terminal.save_completed.connect(_on_save_completed)
	mod_bench.mod_requested.connect(_on_mod_requested)
	mod_shop.shop_closed.connect(_on_mod_shop_closed)
	skill_board.skill_requested.connect(_on_skill_requested)
	skill_shop.shop_closed.connect(_on_skill_shop_closed)
	contract_panel.contract_selected.connect(_on_contract_selected)
	stats_terminal.stats_requested.connect(_on_stats_requested)
	stats_panel.closed.connect(_on_stats_closed)

	# Loadout panel signals
	loadout_panel.deploy_confirmed.connect(_on_loadout_confirmed)
	loadout_panel.loadout_cancelled.connect(_on_loadout_cancelled)

	# Ammo shop signals
	ammo_shop.shop_closed.connect(_on_shop_closed)

	# Close all panels
	deploy_panel.visible = false
	ammo_shop.visible = false
	loadout_panel.visible = false
	mod_shop.visible = false
	skill_shop.visible = false
	contract_panel.visible = false
	stats_panel.visible = false
	save_feedback.visible = false

	_load_level_list()
	_update_credits_display()

	# Ensure a save exists
	if SaveManager.current_slot < 0:
		SaveManager.new_game(0)

	# Give starter ammo if inventory is completely empty (first run)
	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})
	if inv.is_empty():
		inv["standard"] = 25
		SaveManager.data["ammo_inventory"] = inv
		SaveManager.save()

	# Hub music
	AudioManager.play_music(&"hub_theme")
	AudioManager.stop_ambient(0.5)

	# Palette reactivity
	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _update_credits_display())

	# Re-grab focus after alt-tab
	get_tree().root.focus_entered.connect(_on_window_focus)


func _process(_delta: float) -> void:
	if active_panel:
		_update_credits_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and active_panel:
		_close_active_panel()
		get_viewport().set_input_as_handled()


func _open_panel(panel: Control) -> void:
	if active_panel:
		active_panel.visible = false
	active_panel = panel
	panel.visible = true
	_dimmer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Disable player input while panel is open
	if _player:
		_player.set_process_input(false)
		_player.set_physics_process(false)
	# Focus the first focusable child so arrow keys work immediately
	_focus_first_button(panel)


func _focus_first_button(node: Control) -> void:
	## Collect all buttons, chain focus neighbors, focus the first one.
	var buttons: Array[Button] = []
	_collect_buttons(node, buttons)
	_chain_focus_neighbors(buttons)
	for btn in buttons:
		if btn.visible and not btn.disabled:
			btn.grab_focus()
			return


func _collect_buttons(node: Node, out: Array[Button]) -> void:
	## Recursively gather all visible Buttons in tree order.
	if node is Button and node.visible:
		out.append(node)
	for child in node.get_children():
		_collect_buttons(child, out)


func _chain_focus_neighbors(buttons: Array[Button]) -> void:
	## Link buttons so Up/Down arrows traverse the full list, wrapping around.
	if buttons.size() < 2:
		return
	for i in range(buttons.size()):
		var prev_idx := (i - 1) % buttons.size()
		var next_idx := (i + 1) % buttons.size()
		buttons[i].focus_neighbor_top = buttons[prev_idx].get_path()
		buttons[i].focus_neighbor_bottom = buttons[next_idx].get_path()


func _close_active_panel() -> void:
	if active_panel:
		active_panel.visible = false
		active_panel = null
	_dimmer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Re-enable player input
	if _player:
		_player.set_process_input(true)
		_player.set_physics_process(true)
	_update_credits_display()


## ── Level List ───────────────────────────────────────────────────────────────

func _load_level_list() -> void:
	_level_data_cache.clear()
	for path in LEVEL_LIST:
		var data := load(path) as LevelData
		if data:
			_level_data_cache.append(data)


func _populate_mission_buttons() -> void:
	for child in mission_list.get_children():
		child.queue_free()

	var credits: int = SaveManager.get_credits()
	for data in _level_data_cache:
		var btn := Button.new()

		if not data.is_unlocked():
			btn.text = "LOCKED: %s — Requires: %s" % [data.level_name, data.get_unlock_requirements_text()]
			btn.disabled = true
		elif data.entry_fee > 0:
			btn.text = "%s — $%d entry" % [data.level_name, data.entry_fee]
			if credits < data.entry_fee:
				btn.text += " (can't afford)"
				btn.disabled = true
		else:
			btn.text = "%s — FREE" % data.level_name

		btn.pressed.connect(_on_level_selected.bind(data))
		AudioManager.wire_button(btn)
		mission_list.add_child(btn)


## ── Deploy Board ─────────────────────────────────────────────────────────────

func _on_deploy_requested() -> void:
	_populate_mission_buttons()
	_open_panel(deploy_panel)


func _on_level_selected(data: LevelData) -> void:
	selected_level_path = data.scene_path
	selected_level_data = data
	# Close mission panel, open contract selection
	deploy_panel.visible = false
	contract_panel.open(selected_level_path)
	active_panel = contract_panel


## ── Contract Panel ──────────────────────────────────────────────────────────

func _on_contract_selected(contract: Contract) -> void:
	RunManager.active_contract = contract
	# Close contract panel, open loadout
	contract_panel.visible = false
	loadout_panel.open()
	active_panel = loadout_panel


## ── Loadout Panel ───────────────────────────────────────────────────────────

func _on_loadout_confirmed(loadout: Dictionary) -> void:
	# Charge entry fee
	if selected_level_data and selected_level_data.entry_fee > 0:
		SaveManager.add_credits(-selected_level_data.entry_fee)
		SaveManager.save()
	_close_active_panel()
	RunManager.deploy(selected_level_path, loadout)


func _on_loadout_cancelled() -> void:
	# Go back to contract selection
	loadout_panel.visible = false
	RunManager.active_contract = null
	contract_panel.open(selected_level_path)
	active_panel = contract_panel


## ── Ammo Crate ──────────────────────────────────────────────────────────────

func _on_ammo_crate_requested() -> void:
	ammo_shop.open()
	_open_panel(ammo_shop)


func _on_shop_closed() -> void:
	_close_active_panel()


## ── Mod Bench ───────────────────────────────────────────────────────────

func _on_mod_requested() -> void:
	mod_shop.open()
	_open_panel(mod_shop)


func _on_mod_shop_closed() -> void:
	_close_active_panel()


## ── Skill Board ─────────────────────────────────────────────────────────

func _on_skill_requested() -> void:
	skill_shop.open()
	_open_panel(skill_shop)


func _on_skill_shop_closed() -> void:
	_close_active_panel()


## ── Stats Terminal ───────────────────────────────────────────────────────

func _on_stats_requested() -> void:
	stats_panel.open(LEVEL_LIST)
	_open_panel(stats_panel)


func _on_stats_closed() -> void:
	_close_active_panel()


## ── Save Terminal ────────────────────────────────────────────────────────────

func _on_save_completed() -> void:
	save_feedback.visible = true
	save_feedback.text = "GAME SAVED"
	await get_tree().create_timer(2.0).timeout
	save_feedback.visible = false


## ── Credits ──────────────────────────────────────────────────────────────────

func _on_window_focus() -> void:
	if active_panel:
		_focus_first_button(active_panel)


func _update_credits_display() -> void:
	credits_label.text = "Credits: $%d | XP: %d" % [SaveManager.get_credits(), SaveManager.get_xp()]
	credits_label.add_theme_color_override("font_color", PaletteManager.get_color(&"accent_loot"))
