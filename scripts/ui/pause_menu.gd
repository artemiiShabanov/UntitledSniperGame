extends CanvasLayer
## Pause menu — ESC during a run. Pauses game tree.
## Added as autoload so it works in any scene.

var is_paused: bool = false

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var abandon_btn: Button = $Panel/VBox/AbandonButton
@onready var settings_screen: PanelContainer = $SettingsScreen


func _ready() -> void:
	layer = 100
	panel.visible = false
	settings_screen.visible = false
	resume_btn.pressed.connect(_resume)
	settings_btn.pressed.connect(_open_settings)
	abandon_btn.pressed.connect(_abandon_run)
	settings_screen.closed.connect(_close_settings)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused:
			_resume()
		elif _can_pause():
			_pause()


func _can_pause() -> bool:
	## Allow pause in hub and during active gameplay.
	return RunManager.game_state in [
		RunManager.GameState.HUB,
		RunManager.GameState.IN_RUN,
		RunManager.GameState.EXTRACTING,
	]


func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	panel.visible = true
	settings_screen.visible = false
	abandon_btn.visible = RunManager.game_state != RunManager.GameState.HUB
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	panel.visible = false
	settings_screen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	panel.visible = false
	settings_screen.open()


func _close_settings() -> void:
	settings_screen.visible = false
	panel.visible = true


func _abandon_run() -> void:
	# Treat as a death — lose credits and ammo
	_resume()
	RunManager.carried_ammo = {}
	RunManager.run_credits = 0
	RunManager.is_dead = true
	SaveManager.increment_stat("total_deaths")
	SaveManager.commit_run_stats(RunManager.run_stats, RunManager.current_level_path, false)
	SaveManager.save()
	RunManager.go_to_hub()
