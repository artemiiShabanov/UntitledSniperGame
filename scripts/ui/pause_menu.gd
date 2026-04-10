extends CanvasLayer
## Pause menu — ESC during a run. Pauses game tree.
## Added as autoload so it works in any scene.

var is_paused: bool = false

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var abandon_btn: Button = $Panel/VBox/AbandonButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton
@onready var settings_screen: PanelContainer = $SettingsScreen

## Quit confirmation
var _quit_confirm: PanelContainer


func _ready() -> void:
	layer = 100
	dimmer.visible = false
	panel.visible = false
	settings_screen.visible = false
	resume_btn.pressed.connect(_resume)
	settings_btn.pressed.connect(_open_settings)
	abandon_btn.pressed.connect(_abandon_run)
	quit_btn.pressed.connect(_show_quit_confirm)
	settings_screen.closed.connect(_close_settings)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Wire sounds to all buttons
	AudioManager.wire_buttons(panel)

	# Build quit confirmation dialog
	_build_quit_confirm()

	# Re-grab focus after alt-tab
	get_tree().root.focus_entered.connect(_on_window_focus)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _quit_confirm and _quit_confirm.visible:
			_hide_quit_confirm()
		elif is_paused:
			_resume()
		elif _can_pause():
			_pause()


func _can_pause() -> bool:
	return RunManager.game_state in [
		RunManager.GameState.HUB,
		RunManager.GameState.IN_RUN,
		RunManager.GameState.EXTRACTING,
	]


func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	dimmer.visible = true
	panel.visible = true
	settings_screen.visible = false
	abandon_btn.visible = RunManager.game_state != RunManager.GameState.HUB
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_btn.grab_focus()


func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	dimmer.visible = false
	panel.visible = false
	settings_screen.visible = false
	if _quit_confirm:
		_quit_confirm.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	panel.visible = false
	settings_screen.open()


func _close_settings() -> void:
	settings_screen.visible = false
	panel.visible = true
	resume_btn.grab_focus()


func _abandon_run() -> void:
	_resume()
	RunManager.run_score = 0
	RunManager.is_dead = true
	SaveManager.increment_stat("total_deaths")
	SaveManager.commit_run_stats(RunManager.run_stats.to_dict(), RunManager.current_level_path, false)
	SaveManager.save()
	RunManager.go_to_hub()


## ── Quit Confirmation ───────────────────────────────────────────────────────

func _build_quit_confirm() -> void:
	_quit_confirm = PanelContainer.new()
	_quit_confirm.visible = false
	_quit_confirm.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_quit_confirm.custom_minimum_size = Vector2(600, 280)
	_quit_confirm.position -= _quit_confirm.custom_minimum_size / 2

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_quit_confirm.add_child(vbox)

	var warning := Label.new()
	warning.text = "QUIT TO DESKTOP?"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_font_size_override("font_size", 42)
	vbox.add_child(warning)

	var sub_label := Label.new()
	sub_label.text = "Unsaved progress will be lost."
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_BG_LIGHT))
	vbox.add_child(sub_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 32)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(180, 56)
	cancel_btn.pressed.connect(_hide_quit_confirm)
	AudioManager.wire_button(cancel_btn, &"menu_cancel")
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Quit"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.pressed.connect(func(): get_tree().quit())
	confirm_btn.add_theme_color_override("font_color", PaletteManager.get_color(PaletteManager.SLOT_DANGER))
	AudioManager.wire_button(confirm_btn, &"menu_confirm")
	btn_row.add_child(confirm_btn)

	add_child(_quit_confirm)


func _on_window_focus() -> void:
	if not is_paused:
		return
	if _quit_confirm and _quit_confirm.visible:
		var btn_row: HBoxContainer = _quit_confirm.get_child(0).get_child(2)
		btn_row.get_child(0).grab_focus()
	elif panel.visible:
		resume_btn.grab_focus()


func _show_quit_confirm() -> void:
	panel.visible = false
	_quit_confirm.visible = true
	# Focus cancel by default (safe option)
	var btn_row: HBoxContainer = _quit_confirm.get_child(0).get_child(2)
	btn_row.get_child(0).grab_focus()


func _hide_quit_confirm() -> void:
	_quit_confirm.visible = false
	panel.visible = true
	quit_btn.grab_focus()
