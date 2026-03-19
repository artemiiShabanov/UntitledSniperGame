extends Node3D
## Hub scene — player walks around, interacts with stations.

const DEV_TEST_LEVEL := "res://scenes/dev/dev_test.tscn"

@onready var deploy_board: Interactable = $DeployBoard
@onready var ammo_crate: Interactable = $AmmoCrate
@onready var save_terminal: Interactable = $SaveTerminal

## UI panels
@onready var deploy_panel: Control = $StationUI/DeployPanel
@onready var ammo_panel: Control = $StationUI/AmmoPanel
@onready var save_feedback: Label = $StationUI/SaveFeedback

## Ammo UI elements
@onready var ammo_slider: HSlider = $StationUI/AmmoPanel/VBox/AmmoSlider
@onready var ammo_label: Label = $StationUI/AmmoPanel/VBox/AmmoLabel
@onready var ammo_confirm_btn: Button = $StationUI/AmmoPanel/VBox/ConfirmButton

## Credits display
@onready var credits_label: Label = $StationUI/CreditsLabel

var active_panel: Control = null


func _ready() -> void:
	# Just set state — we're already in the hub scene, no need to change_scene
	RunManager._set_game_state(RunManager.GameState.HUB)
	RunManager.is_dead = false

	deploy_board.deploy_requested.connect(_on_deploy_requested)
	ammo_crate.loadout_requested.connect(_on_loadout_requested)
	save_terminal.save_completed.connect(_on_save_completed)

	# Close all panels
	deploy_panel.visible = false
	ammo_panel.visible = false
	save_feedback.visible = false

	_update_credits_display()

	# Ensure a save exists
	if SaveManager.current_slot < 0:
		SaveManager.new_game(0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and active_panel:
		_close_active_panel()


func _open_panel(panel: Control) -> void:
	if active_panel:
		active_panel.visible = false
	active_panel = panel
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_active_panel() -> void:
	if active_panel:
		active_panel.visible = false
		active_panel = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## ── Deploy Board ─────────────────────────────────────────────────────────────

func _on_deploy_requested() -> void:
	_open_panel(deploy_panel)


func _on_deploy_button_pressed() -> void:
	_close_active_panel()
	# Gather ammo loadout from save inventory
	var loadout: Dictionary = {}
	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})
	# For now, take all standard ammo
	if inv.get("standard", 0) > 0:
		loadout["standard"] = inv["standard"]
		inv["standard"] = 0
	else:
		# Give starter ammo if inventory is empty
		loadout["standard"] = 25
	SaveManager.save()
	RunManager.deploy(DEV_TEST_LEVEL, loadout)


## ── Ammo Crate ───────────────────────────────────────────────────────────────

func _on_loadout_requested() -> void:
	_open_panel(ammo_panel)
	var inv: Dictionary = SaveManager.data.get("ammo_inventory", {})
	var available: int = inv.get("standard", 0)
	ammo_slider.max_value = available
	ammo_slider.value = available
	_update_ammo_label()


func _on_ammo_slider_changed(value: float) -> void:
	_update_ammo_label()


func _update_ammo_label() -> void:
	ammo_label.text = "Standard ammo: %d / %d" % [int(ammo_slider.value), int(ammo_slider.max_value)]


func _on_ammo_confirm() -> void:
	# This just pre-selects how much to take — deploy() reads it
	_close_active_panel()


## ── Save Terminal ────────────────────────────────────────────────────────────

func _on_save_completed() -> void:
	save_feedback.visible = true
	save_feedback.text = "GAME SAVED"
	await get_tree().create_timer(2.0).timeout
	save_feedback.visible = false


## ── Credits ──────────────────────────────────────────────────────────────────

func _update_credits_display() -> void:
	credits_label.text = "Credits: %d | XP: %d" % [SaveManager.get_credits(), SaveManager.get_xp()]
