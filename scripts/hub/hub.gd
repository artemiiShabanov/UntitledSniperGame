extends Node3D
## Hub scene — player walks around, interacts with stations.
## Stations: Deploy Board, Armory (mods), Skill Board, War Room, Stats, Palette, Save.

## Available levels — only Castle Keep for now
var LEVEL_LIST: Array[String] = [
	"res://data/levels/castle_keep_data.tres",
]

@onready var deploy_board: Interactable = $DeployBoard
@onready var mod_bench: Interactable = $ModBench
@onready var skill_board: Interactable = $SkillBoard
@onready var war_room_station: Interactable = $WarRoomStation
@onready var stats_terminal: Interactable = $StatsTerminal
@onready var palette_station: Interactable = $PaletteStation

## UI layer
@onready var station_ui: CanvasLayer = $StationUI

## UI panels
@onready var deploy_panel: Control = $StationUI/DeployPanel
@onready var armory: Control = $StationUI/Armory
@onready var skill_shop: Control = $StationUI/SkillShop
@onready var war_room: Control = $StationUI/WarRoom
@onready var stats_panel: Control = $StationUI/StatsPanel
@onready var palette_panel: Control = $StationUI/PalettePanel

## Deploy UI
@onready var mission_list: VBoxContainer = $StationUI/DeployPanel/VBox/MissionList

## XP display
@onready var xp_display: Label = $StationUI/XPLabel

var active_panel: Control = null
var selected_level_path: String = ""
var selected_level_data: LevelData = null
var _level_data_cache: Array[LevelData] = []

## Background dimmer
var _dimmer: ColorRect
var _player: CharacterBody3D


func _ready() -> void:
	RunManager._set_game_state(RunManager.GameState.HUB)
	RunManager.is_dead = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

	# Create dimmer
	_dimmer = ColorRect.new()
	_dimmer.name = "Dimmer"
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(PaletteManager.GS_DARK, 0.7)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.visible = false
	station_ui.add_child(_dimmer)
	station_ui.move_child(_dimmer, 0)

	deploy_board.deploy_requested.connect(_on_deploy_requested)
	mod_bench.mod_requested.connect(_on_mod_requested)
	armory.shop_closed.connect(_on_armory_closed)
	skill_board.skill_requested.connect(_on_skill_requested)
	skill_shop.shop_closed.connect(_on_skill_shop_closed)
	war_room_station.war_room_requested.connect(_on_war_room_requested)
	war_room.panel_closed.connect(_on_war_room_closed)
	stats_terminal.stats_requested.connect(_on_stats_requested)
	stats_panel.closed.connect(_on_stats_closed)
	palette_station.palette_requested.connect(_on_palette_requested)
	palette_panel.panel_closed.connect(_on_palette_closed)

	# Close all panels
	deploy_panel.visible = false
	armory.visible = false
	skill_shop.visible = false
	war_room.visible = false
	stats_panel.visible = false
	palette_panel.visible = false

	_load_level_list()
	_update_xp_display()

	if SaveManager.current_slot < 0:
		SaveManager.new_game(0)

	AudioManager.play_music(&"hub_theme")
	AudioManager.stop_ambient(0.5)

	PaletteManager.palette_changed.connect(func(_p: PaletteResource) -> void: _update_xp_display())
	get_tree().root.focus_entered.connect(_on_window_focus)


func _process(_delta: float) -> void:
	if active_panel:
		_update_xp_display()


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
	if _player:
		_player.set_process_input(false)
		_player.set_physics_process(false)
	_focus_first_button(panel)


func _focus_first_button(node: Control) -> void:
	var buttons: Array[Button] = []
	UIUtils.collect_buttons(node, buttons)
	UIUtils.chain_focus(buttons)
	for btn in buttons:
		if btn.visible and not btn.disabled:
			btn.grab_focus()
			return


func _close_active_panel() -> void:
	if active_panel:
		active_panel.visible = false
		active_panel = null
	_dimmer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _player:
		_player.set_process_input(true)
		_player.set_physics_process(true)
	_update_xp_display()


## ── Level List ───────────────────────────────────────────────────────────────

func _load_level_list() -> void:
	_level_data_cache.clear()
	for path in LEVEL_LIST:
		if ResourceLoader.exists(path):
			var data := load(path) as LevelData
			if data:
				_level_data_cache.append(data)


func _populate_mission_buttons() -> void:
	UIUtils.clear_children(mission_list)
	for data in _level_data_cache:
		var btn := Button.new()
		btn.text = data.level_name
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
	_close_active_panel()
	RunManager.deploy(selected_level_path)


## ── Armory ──────────────────────────────────────────────────────────────

func _on_mod_requested() -> void:
	armory.open()
	_open_panel(armory)


func _on_armory_closed() -> void:
	_close_active_panel()


## ── Skill Board ─────────────────────────────────────────────────────────

func _on_skill_requested() -> void:
	skill_shop.open()
	_open_panel(skill_shop)


func _on_skill_shop_closed() -> void:
	_close_active_panel()


## ── War Room ────────────────────────────────────────────────────────────

func _on_war_room_requested() -> void:
	war_room.open()
	_open_panel(war_room)


func _on_war_room_closed() -> void:
	_close_active_panel()


## ── Stats Terminal ───────────────────────────────────────────────────────

func _on_stats_requested() -> void:
	stats_panel.open(LEVEL_LIST)
	_open_panel(stats_panel)


func _on_stats_closed() -> void:
	_close_active_panel()


## ── Palette Station ─────────────────────────────────────────────────────

func _on_palette_requested() -> void:
	SaveManager.check_and_unlock_palettes()
	palette_panel.open()
	_open_panel(palette_panel)


func _on_palette_closed() -> void:
	_close_active_panel()


## ── XP Display ──────────────────────────────────────────────────────────────

func _on_window_focus() -> void:
	if active_panel:
		_focus_first_button(active_panel)


func _update_xp_display() -> void:
	xp_display.text = "XP: %d" % SaveManager.get_xp()
	xp_display.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_ACCENT_LOOT))
